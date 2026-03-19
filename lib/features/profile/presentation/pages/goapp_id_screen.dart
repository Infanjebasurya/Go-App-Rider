import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goapp/core/di/injection.dart';
import 'package:goapp/core/storage/profile_display_store.dart';
import 'package:goapp/core/storage/user_cache_store.dart';
import 'package:goapp/core/theme/app_colors.dart';
import 'package:goapp/core/widgets/app_app_bar.dart';
import 'package:goapp/features/auth/presentation/theme/auth_ui_tokens.dart';
import 'package:goapp/features/auth/presentation/widgets/snackbar_utils.dart';
import 'package:goapp/features/profile/presentation/cubit/profile_edit_cubit.dart';
import 'package:goapp/features/profile/presentation/cubit/profile_edit_state.dart';

class GoAppIdScreen extends StatelessWidget {
  const GoAppIdScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProfileEditCubit>(
      create: (_) => sl<ProfileEditCubit>(),
      child: const _GoAppIdView(),
    );
  }
}

class _GoAppIdView extends StatelessWidget {
  const _GoAppIdView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppAppBar(
        title: 'GoApp ID',
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        actions: <Widget>[
          IconButton(
            icon: const Icon(
              Icons.share_outlined,
              color: AuthUiColors.brandGreen,
              size: 22,
            ),
            onPressed: () {
              SnackBarUtils.show(context, 'Share will be added soon.');
            },
          ),
        ],
      ),
      body: BlocBuilder<ProfileEditCubit, ProfileEditState>(
        builder: (BuildContext context, ProfileEditState state) {
          final _GoAppIdData data = _GoAppIdData.fromState(state.data);
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _GoAppIdCard(data: data),
                const SizedBox(height: 18),
                _InfoRow(
                  label: 'LICENSE NUMBER',
                  value: data.licenseNumber,
                  icon: Icons.badge_outlined,
                ),
                _InfoRow(
                  label: 'LICENSE VALIDITY',
                  value: data.licenseValidity,
                  icon: Icons.calendar_today_outlined,
                ),
                _InfoRow(
                  label: 'REGISTERED SINCE',
                  value: data.registeredSince,
                  icon: Icons.history_toggle_off,
                  showDivider: false,
                ),
                const SizedBox(height: 180),
                const Center(child: _SecureIdFooter()),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _GoAppIdCard extends StatelessWidget {
  const _GoAppIdCard({required this.data});

  final _GoAppIdData data;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double cardWidth = constraints.maxWidth;
        final double cardHeight = cardWidth * 0.66;
        final double horizontalPadding = cardWidth * 0.08;
        final double topPadding = cardWidth * 0.08;
        final double logoWidth = cardWidth * 0.125;
        final double logoHeight = cardWidth * 0.102;
        final double photoWidth = cardWidth * 0.19;
        final double photoHeight = cardWidth * 0.26;
        final double labelFontSize = cardWidth * 0.024;
        final double numberFontSize = cardWidth * 0.072;
        final double metaValueFontSize = cardWidth * 0.039;
        final double photoRight = cardWidth * 0.08;
        final double photoTop = cardWidth * 0.08;
        final double textRightInset =
            photoWidth + photoRight + (cardWidth * 0.05);
        final double licenseTop = topPadding + logoHeight + (cardWidth * 0.08);
        final double bottomTop = cardHeight - (cardWidth * 0.155);

        return Container(
          width: double.infinity,
          height: cardHeight,
          decoration: BoxDecoration(
            color: const Color(0xFF064E3B),
            borderRadius: BorderRadius.circular(22),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 22,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: <Widget>[
              Positioned(
                left: horizontalPadding,
                top: topPadding,
                child: Container(
                  width: logoWidth,
                  height: logoHeight,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.84),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Logo',
                    style: TextStyle(
                      fontSize: cardWidth * 0.031,
                      fontWeight: FontWeight.w600,
                      color: AppColors.hexFF444444,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: photoRight,
                top: photoTop,
                child: _DriverPhotoCard(
                  imagePath: data.photoPath,
                  width: photoWidth,
                  height: photoHeight,
                ),
              ),
              Positioned(
                left: horizontalPadding,
                right: textRightInset,
                top: licenseTop,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'LICENSE NUMBER',
                      style: TextStyle(
                        fontSize: labelFontSize,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF77A79A),
                        letterSpacing: 3.1,
                      ),
                    ),
                    SizedBox(height: cardWidth * 0.022),
                    Text(
                      data.licenseNumber,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: numberFontSize,
                        fontWeight: FontWeight.w500,
                        color: AppColors.white,
                        letterSpacing: 1.5,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: horizontalPadding,
                top: bottomTop,
                child: _CardMetaBlock(
                  label: 'LICENSE VALIDITY',
                  value: data.validityStatus,
                  labelFontSize: labelFontSize,
                  valueFontSize: metaValueFontSize,
                ),
              ),
              Positioned(
                left: cardWidth * 0.68,
                top: bottomTop,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'STATUS',
                      style: TextStyle(
                        fontSize: labelFontSize,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF77A79A),
                        letterSpacing: 2.6,
                      ),
                    ),
                    SizedBox(height: cardWidth * 0.018),
                    Row(
                      children: <Widget>[
                        Icon(
                          Icons.circle,
                          size: cardWidth * 0.022,
                          color: AppColors.verifiedMint,
                        ),
                        SizedBox(width: cardWidth * 0.02),
                        Text(
                          'Verified',
                          style: TextStyle(
                            fontSize: metaValueFontSize,
                            fontWeight: FontWeight.w500,
                            color: AppColors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DriverPhotoCard extends StatelessWidget {
  const _DriverPhotoCard({
    required this.imagePath,
    required this.width,
    required this.height,
  });

  final String? imagePath;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final Widget child;
    if (imagePath != null &&
        imagePath!.isNotEmpty &&
        File(imagePath!).existsSync()) {
      child = ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(imagePath!),
          fit: BoxFit.cover,
          width: width,
          height: height,
        ),
      );
    } else {
      child = Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.hexFF3A3A3A,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Icon(Icons.person, color: AppColors.white54, size: width * 0.48),
      );
    }

    return child;
  }
}

class _CardMetaBlock extends StatelessWidget {
  const _CardMetaBlock({
    required this.label,
    required this.value,
    required this.labelFontSize,
    required this.valueFontSize,
  });

  final String label;
  final String value;
  final double labelFontSize;
  final double valueFontSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: TextStyle(
            fontSize: labelFontSize,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF77A79A),
            letterSpacing: 2.4,
          ),
        ),
        SizedBox(height: valueFontSize * 0.22),
        Text(
          value,
          style: TextStyle(
            fontSize: valueFontSize,
            fontWeight: FontWeight.w500,
            color: AppColors.white,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
    this.showDivider = true,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: showDivider
              ? const BorderSide(color: AppColors.hexFFF0F0F0)
              : BorderSide.none,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.hexFF888888,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.hexFF3D4F63,
                  ),
                ),
              ],
            ),
          ),
          Icon(icon, color: AppColors.hexFF6E6E6E, size: 24),
        ],
      ),
    );
  }
}

class _SecureIdFooter extends StatelessWidget {
  const _SecureIdFooter();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          children: const <Widget>[
            Icon(
              Icons.verified_user_outlined,
              color: AuthUiColors.brandGreen,
              size: 16,
            ),
            SizedBox(width: 4),
            Text(
              'GoApp SecureID',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AuthUiColors.brandGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        const Text(
          'Encrypted & Cryptographically Signed',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: AppColors.hexFFAAAAAA,
          ),
        ),
      ],
    );
  }
}

class _GoAppIdData {
  const _GoAppIdData({
    required this.licenseNumber,
    required this.licenseValidity,
    required this.registeredSince,
    required this.validityStatus,
    required this.photoPath,
  });

  final String licenseNumber;
  final String licenseValidity;
  final String registeredSince;
  final String validityStatus;
  final String? photoPath;

  factory _GoAppIdData.fromState(ProfileEditData? state) {
    final cached = UserCacheStore.read();
    final String id = (cached?.id ?? '').trim();
    return _GoAppIdData(
      licenseNumber: id.isNotEmpty ? id : 'TN0220240000519',
      licenseValidity: '12 Jan 2030',
      registeredSince: '15 Mar 2021',
      validityStatus: 'Active & Verified',
      photoPath: ProfileDisplayStore.photoPath(),
    );
  }
}
