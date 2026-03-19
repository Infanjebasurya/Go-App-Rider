import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goapp/features/auth/presentation/theme/auth_ui_tokens.dart';
import 'package:goapp/features/documents/presentation/cubit/documents_cubit.dart';
import 'package:goapp/features/documents/presentation/cubit/documents_state.dart';
import 'package:goapp/features/documents/presentation/model/document_model.dart';
import 'package:goapp/features/documents/presentation/pages/document_detail_screen.dart';
import 'package:goapp/core/widgets/app_app_bar.dart';
import 'package:goapp/core/widgets/shadow_button.dart';
import 'package:goapp/core/theme/app_colors.dart';
import 'package:goapp/core/di/injection.dart';

class DocumentsScreen extends StatelessWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<DocumentsCubit>(),
      child: const _DocumentsView(),
    );
  }
}

class _DocumentsView extends StatefulWidget {
  const _DocumentsView();

  @override
  State<_DocumentsView> createState() => _DocumentsViewState();
}

class _DocumentsViewState extends State<_DocumentsView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: _buildAppBar(context),
      body: BlocBuilder<DocumentsCubit, DocumentsState>(
        builder: (context, state) {
          if (state is DocumentsLoading || state is DocumentsInitial) {
            return const _LoadingView();
          }
          if (state is DocumentsError) {
            return _ErrorView(message: state.message);
          }
          if (state is DocumentsLoaded) {
            return _LoadedView(state: state);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppAppBar(
      backgroundColor: AppColors.white,
      elevation: 0,
      centerTitle: true,
      title: const Text('Documents'),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: AppColors.hexFFEEEEEE, height: 1),
      ),
    );
  }
}

class _LoadedView extends StatelessWidget {
  final DocumentsLoaded state;

  const _LoadedView({required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
            itemCount: state.documents.length,
            separatorBuilder: (context, index) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final doc = state.documents[index];
              return _DocumentCard(document: doc);
            },
          ),
        ),
        if (state.allVerified) const _VerifiedBanner(),
      ],
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final DocumentModel document;

  const _DocumentCard({required this.document});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DocumentDetailScreen(document: document),
          ),
        );
        if (!context.mounted) return;
        context.read<DocumentsCubit>().refresh();
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border(
            left: BorderSide(color: _borderColor(document.status), width: 4),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.hexFFF5F5F5,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _iconData(document.iconAsset),
                  color: AppColors.hexFF444444,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.hexFF1A1A1A,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      document.subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.hexFFAAAAAA,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: document.status),
            ],
          ),
        ),
      ),
    );
  }

  Color _borderColor(DocumentStatus status) {
    switch (status) {
      case DocumentStatus.verified:
        return AuthUiColors.brandGreen;
      case DocumentStatus.pending:
        return AppColors.hexFFFFA726;
      case DocumentStatus.rejected:
        return AppColors.hexFFEF5350;
      case DocumentStatus.notUploaded:
        return AppColors.hexFFCCCCCC;
    }
  }

  IconData _iconData(String asset) {
    switch (asset) {
      case 'driving_license':
        return Icons.badge_outlined;
      case 'vehicle_rc':
        return Icons.directions_car_outlined;
      case 'aadhaar_card':
        return Icons.fingerprint;
      case 'pan_card':
        return Icons.credit_card;
      case 'bank_account':
      case 'link bank account':
        return Icons.account_balance_outlined;
      default:
        return Icons.description_outlined;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final DocumentStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final label = _label(status);
    final color = _color(status);
    final icon = _icon(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  String _label(DocumentStatus s) {
    switch (s) {
      case DocumentStatus.verified:
        return 'VERIFIED';
      case DocumentStatus.pending:
        return 'VERIFIED';
      case DocumentStatus.rejected:
        return 'REJECTED';
      case DocumentStatus.notUploaded:
        return 'UPLOAD REQUIRED';
    }
  }

  Color _color(DocumentStatus s) {
    switch (s) {
      case DocumentStatus.verified:
        return AuthUiColors.brandGreen;
      case DocumentStatus.pending:
        return AppColors.hexFFFFA726;
      case DocumentStatus.rejected:
        return AppColors.hexFFEF5350;
      case DocumentStatus.notUploaded:
        return AppColors.hexFF888888;
    }
  }

  IconData _icon(DocumentStatus s) {
    switch (s) {
      case DocumentStatus.verified:
        return Icons.check_circle_outline;
      case DocumentStatus.pending:
        return Icons.hourglass_top_outlined;
      case DocumentStatus.rejected:
        return Icons.cancel_outlined;
      case DocumentStatus.notUploaded:
        return Icons.upload_outlined;
    }
  }
}

class _VerifiedBanner extends StatelessWidget {
  const _VerifiedBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: const Text(
        'ALL YOUR DOCUMENTS ARE VERIFIED AND UP TO DATE\n'
        'YOU HAVE FULL ACCESS TO ALL PREMIUM PLATFORM FEATURES.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.hexFFAAAAAA,
          letterSpacing: 0.3,
          height: 1.6,
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      itemCount: 5,
      separatorBuilder: (context, index) => const SizedBox(height: 14),
      itemBuilder: (context, index) => const _SkeletonCard(),
    );
  }
}

class _SkeletonCard extends StatefulWidget {
  const _SkeletonCard();

  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween<double>(
      begin: -1.5,
      end: 1.5,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        return Container(
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: const Border(
              left: BorderSide(color: AppColors.hexFFE0E0E0, width: 4),
            ),
            gradient: LinearGradient(
              begin: Alignment(_anim.value - 1, 0),
              end: Alignment(_anim.value + 1, 0),
              colors: const [
                AppColors.hexFFF0F0F0,
                AppColors.hexFFE0E0E0,
                AppColors.hexFFF0F0F0,
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;

  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: AppColors.hexFFEF5350,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(fontSize: 14, color: AppColors.hexFF888888),
          ),
          const SizedBox(height: 20),
          ShadowButton(
            onPressed: () => context.read<DocumentsCubit>().refresh(),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AuthUiColors.brandGreen,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
