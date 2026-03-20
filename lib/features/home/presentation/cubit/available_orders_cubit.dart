import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goapp/features/home/data/datasources/ride_expire_remote_data_source.dart';
import 'package:goapp/features/home/presentation/cubit/available_orders_state.dart';

class AvailableOrdersCubit extends Cubit<AvailableOrdersState> {
  AvailableOrdersCubit({RideExpireRemoteDataSource? rideExpireApi})
    : _rideExpireApi = rideExpireApi ?? RideExpireRemoteDataSourceImpl(),
      super(const AvailableOrdersState());

  static const Duration _tickDuration = Duration(milliseconds: 100);
  static const Duration _perOrderDuration = Duration(seconds: 15);

  // Mock ride IDs used by the demo available-orders screen.
  static const List<String> _demoRideIds = <String>[
    '16a241d3-c058-4251-ba33-a5f16e1f7f3e',
    '53b3d430-f67b-4ee9-8f92-2f66329fa5b1',
    '6f3cfe3b-fc3a-4f5d-aea4-dc9a65a4e38d',
    '9c6a7e9a-2b0a-4c2b-b98d-7c8b2fca3c89',
  ];

  final RideExpireRemoteDataSource _rideExpireApi;
  Timer? _timer;

  void start() {
    _timer?.cancel();

    // If all orders are gone (or the flow completed), restart the stream.
    if (state.isExpired ||
        (!state.showFirstOrder &&
        !state.showSecondOrder &&
        !state.showThirdOrder &&
        !state.showFourthOrder)) {
      emit(const AvailableOrdersState());
    }

    final double step =
        _tickDuration.inMilliseconds / _perOrderDuration.inMilliseconds;

    _timer = Timer.periodic(_tickDuration, (_) {
      if (state.isExpiring || state.isExpired) return;
      final double nextProgress = (state.progress + step).clamp(0, 1);
      if (nextProgress < 1) {
        emit(state.copyWith(progress: nextProgress));
        return;
      }

      unawaited(_expireActiveOrder());
    });
  }

  Future<void> _expireActiveOrder() async {
    if (state.isExpiring || state.isExpired) return;

    emit(state.copyWith(isExpiring: true));

    final String rideId = _rideIdForIndex(state.activeOrderIndex);
    try {
      final response = await _rideExpireApi.expireRide(rideId: rideId);
      final String status = (response.status ?? '').trim().toLowerCase();
      final String message = status == 'no_drivers'
          ? 'No drivers available'
          : ((response.message ?? '').trim().isNotEmpty
                ? response.message!.trim()
                : 'Ride expired');

      if (status == 'no_drivers' || state.activeOrderIndex >= 3) {
        _timer?.cancel();
        emit(
          state.copyWith(
            isExpiring: false,
            isExpired: true,
            expireMessage: message,
            showFirstOrder: false,
            showSecondOrder: false,
            showThirdOrder: false,
            showFourthOrder: false,
            progress: 0,
          ),
        );
        _emitSnack(message);
        return;
      }

      switch (state.activeOrderIndex) {
        case 0:
          emit(
            state.copyWith(
              isExpiring: false,
              showFirstOrder: false,
              showSecondOrder: true,
              activeOrderIndex: 1,
              progress: 0,
            ),
          );
          _emitSnack(message);
          return;
        case 1:
          emit(
            state.copyWith(
              isExpiring: false,
              showSecondOrder: false,
              showThirdOrder: true,
              activeOrderIndex: 2,
              progress: 0,
            ),
          );
          _emitSnack(message);
          return;
        case 2:
          emit(
            state.copyWith(
              isExpiring: false,
              showThirdOrder: false,
              showFourthOrder: true,
              activeOrderIndex: 3,
              progress: 0,
            ),
          );
          _emitSnack(message);
          return;
        default:
          _timer?.cancel();
          emit(state.copyWith(isExpiring: false));
          return;
      }
    } catch (error) {
      final String message = _errorMessage(error);
      _timer?.cancel();
      emit(
        state.copyWith(
          isExpiring: false,
          isExpired: true,
          expireMessage: message,
          showFirstOrder: false,
          showSecondOrder: false,
          showThirdOrder: false,
          showFourthOrder: false,
          progress: 0,
        ),
      );
      _emitSnack(message);
    }
  }

  void retry() {
    emit(const AvailableOrdersState());
    start();
  }

  String _rideIdForIndex(int index) {
    if (index >= 0 && index < _demoRideIds.length) return _demoRideIds[index];
    return _demoRideIds.first;
  }

  void _emitSnack(String message) {
    final String trimmed = message.trim();
    if (trimmed.isEmpty || isClosed) return;
    emit(
      state.copyWith(
        snackbarMessage: trimmed,
        snackbarMessageEventId: state.snackbarMessageEventId + 1,
      ),
    );
  }

  String _errorMessage(Object error) {
    final String raw = error.toString();
    const String prefix = 'Exception: ';
    return raw.startsWith(prefix) ? raw.substring(prefix.length) : raw;
  }

  double progressForOrder(int index) {
    if (index < state.activeOrderIndex) return 1;
    if (index == state.activeOrderIndex) return state.progress;
    return 0;
  }

  void stop() {
    _timer?.cancel();
  }

  @override
  Future<void> close() async {
    _timer?.cancel();
    await super.close();
  }
}
