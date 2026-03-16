import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goapp/core/storage/profile_display_store.dart';
import 'package:goapp/core/storage/text_field_store.dart';

import '../../../about/presentation/pages/about_screen.dart';
import '../../../auth/presentation/theme/auth_ui_tokens.dart';
import '../../../demand_planner/presentation/pages/demand_planner_screen.dart';
import '../../../documents/presentation/pages/documents_screen.dart';
import '../../../earnings/presentation/pages/earnings_screen.dart';
import '../../../help_support/presentation/pages/help_support_screen.dart';
import '../../../incentives/presentation/pages/incentives_page.dart';
import '../../../profile/presentation/pages/profile_screen.dart';
import '../../../profile/presentation/pages/goapp_id_screen.dart';
import '../../../rate_app/presentation/pages/rate_app_screen.dart';
import '../../../refer_earn/presentation/pages/refer_earn_screen.dart';
import '../../../ride_history/presentation/pages/ride_history_screen.dart';
import '../cubit/driver_status_cubit.dart';
import 'package:goapp/core/theme/app_colors.dart';

class HomeDrawer extends StatelessWidget {
  const HomeDrawer({super.key, required this.onReopenDrawer});

  final VoidCallback onReopenDrawer;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProfileHeader(context: context, onReopenDrawer: onReopenDrawer),

            const SizedBox(height: 16),

            const Divider(height: 1, color: AppColors.hexFFF0F0F0),
            const SizedBox(height: 16),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DrawerItem(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Earning & Wallet',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EarningsScreen(),
                          ),
                        ).then((_) {
                          onReopenDrawer();
                          if (!context.mounted) return;
                          context.read<DriverCubit>().refreshDashboardMetrics();
                        });
                      },
                    ),
                    _DrawerItem(
                      icon: Icons.badge_outlined,
                      label: 'GoApp ID',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const GoAppIdScreen(),
                          ),
                        ).then((_) => onReopenDrawer());
                      },
                    ),
                    _DrawerItem(
                      icon: Icons.card_giftcard_outlined,
                      label: 'Incentives',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const IncentivesPage(),
                          ),
                        ).then((_) => onReopenDrawer());
                      },
                    ),
                    _DrawerItem(
                      icon: Icons.description_outlined,
                      label: 'Documents',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DocumentsScreen(),
                          ),
                        ).then((_) => onReopenDrawer());
                      },
                    ),
                    _DrawerItem(
                      icon: Icons.insights_outlined,
                      label: 'Demand Planner',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DemandPlannerScreen(),
                          ),
                        ).then((_) => onReopenDrawer());
                      },
                    ),
                    _DrawerItem(
                      icon: Icons.share_outlined,
                      label: 'Refer & Earn',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ReferEarnScreen(),
                          ),
                        ).then((_) => onReopenDrawer());
                      },
                    ),
                    _DrawerItem(
                      icon: Icons.history,
                      label: 'Ride History',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RideHistoryScreen(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 8),
                    const Divider(height: 1, color: AppColors.hexFFF0F0F0),
                    const SizedBox(height: 8),

                    _DrawerItem(
                      icon: Icons.info_outline,
                      label: 'About',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AboutScreen(),
                          ),
                        ).then((_) => onReopenDrawer());
                      },
                    ),
                    _DrawerItem(
                      icon: Icons.star_outline,
                      label: 'Rate App',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RateAppScreen(),
                          ),
                        ).then((_) => onReopenDrawer());
                      },
                    ),
                    _DrawerItem(
                      icon: Icons.help_outline,
                      label: 'Help & Support',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const HelpSupportScreen(),
                          ),
                        ).then((_) => onReopenDrawer());
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatefulWidget {
  final BuildContext context;
  final VoidCallback onReopenDrawer;

  const _ProfileHeader({required this.context, required this.onReopenDrawer});

  @override
  State<_ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<_ProfileHeader> {
  static const String _photoKey = 'profile.photo.path';
  ImageProvider? _avatarProvider;

  @override
  void initState() {
    super.initState();
    _loadAvatarFromStore();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _precacheAvatar();
  }

  void _loadAvatarFromStore() {
    final raw = TextFieldStore.read(_photoKey);
    _avatarProvider = _buildAvatarProvider(raw);
  }

  ImageProvider? _buildAvatarProvider(String? path) {
    if (path == null || path.isEmpty) return null;
    final file = File(path);
    if (!file.existsSync()) return null;
    return ResizeImage(FileImage(file), width: 160, height: 160);
  }

  void _precacheAvatar() {
    final provider = _avatarProvider;
    if (provider == null) return;
    precacheImage(provider, context);
  }

  @override
  Widget build(BuildContext context) {
    final displayName = ProfileDisplayStore.displayName();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: GestureDetector(
        onTap: () {
          Navigator.pop(widget.context);
          Navigator.push(
            widget.context,
            MaterialPageRoute(builder: (_) => const ProfileScreen()),
          ).then((_) => widget.onReopenDrawer());
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AuthUiColors.brandGreen,
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: Container(
                            color: AppColors.hexFF3A3A3A,
                            child: _avatarProvider != null
                                ? Image(
                                    image: _avatarProvider!,
                                    fit: BoxFit.contain,
                                    filterQuality: FilterQuality.low,
                                    gaplessPlayback: true,
                                  )
                                : const Icon(
                                    Icons.person,
                                    size: 44,
                                    color: AppColors.white54,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.hexFF1A1A1A,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AuthUiColors.brandGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AuthUiColors.brandGreen.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.verified,
                          color: AuthUiColors.brandGreen,
                          size: 13,
                        ),
                        const SizedBox(width: 4),
                        const Flexible(
                          child: Text(
                            'PLATINUM MEMBER',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AuthUiColors.brandGreen,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Align(
              alignment: Alignment.bottomRight,
              child: const Icon(
                Icons.chevron_right,
                color: AppColors.gray,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: AuthUiColors.brandGreen.withValues(alpha: 0.08),
      highlightColor: AuthUiColors.brandGreen.withValues(alpha: 0.04),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: AppColors.hexFF444444),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.hexFF1A1A1A,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.gray, size: 20),
          ],
        ),
      ),
    );
  }
}
