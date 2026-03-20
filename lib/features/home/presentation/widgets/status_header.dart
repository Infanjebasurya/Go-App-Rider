import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:goapp/features/auth/presentation/theme/auth_ui_tokens.dart';
import 'package:goapp/core/widgets/app_app_bar.dart';
import 'package:goapp/features/notifications/presentation/pages/notifications_screen.dart';
import '../cubit/driver_status_cubit.dart';
import '../cubit/driver_status_state.dart';
import 'package:goapp/core/theme/app_colors.dart';

class DriverAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DriverAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DriverCubit, DriverState>(
      builder: (context, state) {
        return AppAppBar(
          backgroundColor: state.isOnline
              ? AppColors.transparent
              : AppColors.white,
          elevation: state.isOnline ? 6 : 6,
          shadowColor: AppColors.black12,
          surfaceTintColor: AppColors.transparent,
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          title: _ToggleSwitch(
            isOnline: state.isOnline,
            isBusy: state.isStatusUpdating,
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(
                Icons.notifications_outlined,
                color: AppColors.black54,
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const NotificationsScreen(),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _ToggleSwitch extends StatelessWidget {
  final bool isOnline;
  final bool isBusy;

  const _ToggleSwitch({required this.isOnline, required this.isBusy});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: isBusy,
      child: Opacity(
        opacity: isBusy ? 0.65 : 1,
        child: GestureDetector(
          onTap: () => unawaited(context.read<DriverCubit>().toggleStatus()),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.hexFFF0F0F0,
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Tab(label: 'Offline', isSelected: !isOnline),
                _Tab(label: 'Online', isSelected: isOnline),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool isSelected;

  const _Tab({required this.label, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected
            ? (label == 'Online' ? AuthUiColors.brandGreen : AppColors.gray)
            : AppColors.transparent,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                ),
              ]
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected
              ? (label == 'Online' ? AppColors.white : AppColors.black87)
              : AppColors.black54,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}
