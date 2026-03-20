import 'package:equatable/equatable.dart';

class AvailableOrdersState extends Equatable {
  const AvailableOrdersState({
    this.activeOrderIndex = 0,
    this.progress = 0,
    this.showFirstOrder = true,
    this.showSecondOrder = false,
    this.showThirdOrder = false,
    this.showFourthOrder = false,
    this.isExpiring = false,
    this.isExpired = false,
    this.expireMessage,
    this.snackbarMessage,
    this.snackbarMessageEventId = 0,
  });

  final int activeOrderIndex;
  final double progress;
  final bool showFirstOrder;
  final bool showSecondOrder;
  final bool showThirdOrder;
  final bool showFourthOrder;
  final bool isExpiring;
  final bool isExpired;
  final String? expireMessage;
  final String? snackbarMessage;
  final int snackbarMessageEventId;

  AvailableOrdersState copyWith({
    int? activeOrderIndex,
    double? progress,
    bool? showFirstOrder,
    bool? showSecondOrder,
    bool? showThirdOrder,
    bool? showFourthOrder,
    bool? isExpiring,
    bool? isExpired,
    String? expireMessage,
    String? snackbarMessage,
    int? snackbarMessageEventId,
    bool clearExpireMessage = false,
  }) {
    return AvailableOrdersState(
      activeOrderIndex: activeOrderIndex ?? this.activeOrderIndex,
      progress: progress ?? this.progress,
      showFirstOrder: showFirstOrder ?? this.showFirstOrder,
      showSecondOrder: showSecondOrder ?? this.showSecondOrder,
      showThirdOrder: showThirdOrder ?? this.showThirdOrder,
      showFourthOrder: showFourthOrder ?? this.showFourthOrder,
      isExpiring: isExpiring ?? this.isExpiring,
      isExpired: isExpired ?? this.isExpired,
      expireMessage: clearExpireMessage
          ? null
          : (expireMessage ?? this.expireMessage),
      snackbarMessage: snackbarMessage ?? this.snackbarMessage,
      snackbarMessageEventId:
          snackbarMessageEventId ?? this.snackbarMessageEventId,
    );
  }

  @override
  List<Object> get props => <Object>[
    activeOrderIndex,
    progress,
    showFirstOrder,
    showSecondOrder,
    showThirdOrder,
    showFourthOrder,
    isExpiring,
    isExpired,
    expireMessage ?? '',
    snackbarMessage ?? '',
    snackbarMessageEventId,
  ];
}
