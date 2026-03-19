import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goapp/features/auth/presentation/theme/app_colors.dart';
import 'package:goapp/features/auth/presentation/widgets/appbar.dart';
import 'package:goapp/features/auth/presentation/widgets/snackbar_utils.dart';
import 'package:goapp/core/storage/registration_progress_store.dart';
import 'package:goapp/features/city_vehicle/city_selection/presentation/model/city_model.dart';
import 'package:goapp/features/city_vehicle/vehicle_details/presentation/pages/vehicle_details_screen.dart';
import 'package:goapp/features/city_vehicle/vehicle_selection/presentation/cubit/vehicle_selection_cubit.dart';
import 'package:goapp/features/city_vehicle/vehicle_selection/presentation/model/vehicle_model.dart';
import 'package:goapp/features/city_vehicle/vehicle_selection/presentation/widgets/vehicle_card.dart';
import 'package:goapp/core/widgets/shadow_button.dart';
import 'package:goapp/core/di/injection.dart';

class VehicleSelectionScreen extends StatelessWidget {
  final City selectedCity;

  const VehicleSelectionScreen({super.key, required this.selectedCity});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<VehicleSelectionCubit>(),
      child: _VehicleSelectionView(selectedCity: selectedCity),
    );
  }
}

class _VehicleSelectionView extends StatefulWidget {
  final City selectedCity;

  const _VehicleSelectionView({required this.selectedCity});

  @override
  State<_VehicleSelectionView> createState() => _VehicleSelectionViewState();
}

class _VehicleSelectionViewState extends State<_VehicleSelectionView> {
  @override
  void initState() {
    super.initState();
    unawaited(
      RegistrationProgressStore.setStep(
        RegistrationStep.vehicleSelection,
        cityId: widget.selectedCity.id,
        clearVehicle: true,
        clearDocumentStep: true,
      ),
    );
    unawaited(
      context.read<VehicleSelectionCubit>().loadVehicleTypes(
        city: widget.selectedCity.id,
      ),
    );
  }

  Future<void> _continueWithSelection(Vehicle selectedVehicle) async {
    final messenger = ScaffoldMessenger.of(context);
    final cubit = context.read<VehicleSelectionCubit>();

    final String? message = await cubit.submitSelectedVehicleType(
      vehicleTypeId: selectedVehicle.vehicleTypeId,
    );

    if (!mounted) return;

    final String? error = cubit.state.errorMessage;
    if (error != null) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBarUtils.buildError(error));
      return;
    }

    if (message != null && message.trim().isNotEmpty) {
      messenger.clearSnackBars();
      await messenger
          .showSnackBar(
            SnackBarUtils.build(
              message.trim(),
              duration: const Duration(milliseconds: 900),
            ),
          )
          .closed;
    }

    await RegistrationProgressStore.setStep(
      RegistrationStep.vehicleDetails,
      cityId: widget.selectedCity.id,
      vehicleType: selectedVehicle.type.name,
      vehicleTypeId: selectedVehicle.vehicleTypeId,
      clearDocumentStep: true,
    );

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VehicleDetailsScreen(vehicleType: selectedVehicle.type),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: const AppAppBar(
          title: 'GoApp',
          backEnabled: false,
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, color: AppColors.coolwhite),
          ),
        ),
        body: BlocBuilder<VehicleSelectionCubit, VehicleSelectionState>(
          builder: (context, state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Vehicle Type',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w600,
                          color: AppColors.headingNavy,
                          letterSpacing: -0.6,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Select the vehicle you want do drive with',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.gray.shade500,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (state.isLoading && state.vehicles.isEmpty)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (state.errorMessage != null && state.vehicles.isEmpty)
                  Expanded(
                    child: _VehicleTypesError(
                      message: state.errorMessage!,
                      onRetry: () => context
                          .read<VehicleSelectionCubit>()
                          .loadVehicleTypes(city: widget.selectedCity.id),
                    ),
                  )
                else
                  Expanded(
                    child: Column(
                      children: [
                        if (state.isLoading)
                          const LinearProgressIndicator(minHeight: 2),
                        Expanded(
                          child: ListView(
                            physics: const BouncingScrollPhysics(),
                            children: state.vehicles.map((vehicle) {
                              return VehicleCard(
                                key: ValueKey(vehicle.vehicleTypeId),
                                vehicle: vehicle,
                                isSelected: state.isSelected(vehicle),
                                onTap: () => context
                                    .read<VehicleSelectionCubit>()
                                    .selectVehicle(vehicle),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                _ConfirmButton(
                  enabled: state.hasSelection && !state.isLoading,
                  vehicleLabel: state.selectedVehicle?.label,
                  onTap: () {
                    final selected = state.selectedVehicle;
                    if (selected == null) return;
                    unawaited(_continueWithSelection(selected));
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _VehicleTypesError extends StatelessWidget {
  const _VehicleTypesError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.gray.shade600),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 44,
              child: ShadowButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emerald,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                onPressed: onRetry,
                child: const Text(
                  'Retry',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  final bool enabled;
  final String? vehicleLabel;
  final VoidCallback onTap;

  const _ConfirmButton({
    required this.enabled,
    this.vehicleLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        math.max(
              MediaQuery.viewInsetsOf(context).bottom,
              MediaQuery.of(context).padding.bottom,
            ) +
            20,
      ),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: enabled ? 1.0 : 0.45,
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ShadowButton(
            key: const Key('confirm_vehicle_button'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emerald,
              foregroundColor: AppColors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            onPressed: enabled ? onTap : null,
            child: Text(
              enabled && vehicleLabel != null
                  ? 'Continue with $vehicleLabel'
                  : 'Select a Vehicle',
              style: const TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
