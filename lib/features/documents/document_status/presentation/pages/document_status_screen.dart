import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goapp/core/di/injection.dart';
import 'package:goapp/core/theme/app_colors.dart';
import 'package:goapp/core/widgets/app_app_bar.dart';
import 'package:goapp/core/widgets/shadow_button.dart';
import 'package:goapp/features/documents/aadhaar_upload/presentation/pages/aadhaar_upload_screen.dart';
import 'package:goapp/features/documents/document_status/presentation/cubit/document_status_cubit.dart';
import 'package:goapp/features/documents/document_status/presentation/cubit/document_status_state.dart';
import 'package:goapp/features/documents/document_status/presentation/model/document_status_item_model.dart';
import 'package:goapp/features/documents/pan_upload/presentation/pages/pan_upload_screen.dart';

class DocumentStatusScreen extends StatelessWidget {
  const DocumentStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DocumentStatusCubit>(
      create: (_) => sl<DocumentStatusCubit>()..load(),
      child: const _DocumentStatusView(),
    );
  }
}

class _DocumentStatusView extends StatelessWidget {
  const _DocumentStatusView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: const AppAppBar(title: 'Verification Status'),
      body: BlocBuilder<DocumentStatusCubit, DocumentStatusState>(
        builder: (context, state) {
          if (state is DocumentStatusInitial ||
              state is DocumentStatusLoading) {
            return const _LoadingView();
          }
          if (state is DocumentStatusError) {
            return _ErrorView(message: state.message);
          }
          if (state is DocumentStatusLoaded) {
            if (state.isEmpty) return const _EmptyView();
            return _LoadedView(
              items: state.summary.items,
              verified: state.summary.verifiedCount,
              total: state.summary.totalCount,
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _LoadedView extends StatelessWidget {
  const _LoadedView({
    required this.items,
    required this.verified,
    required this.total,
  });

  final List<DocumentStatusItemModel> items;
  final int verified;
  final int total;

  @override
  Widget build(BuildContext context) {
    final double progress = total <= 0 ? 0 : (verified / total).clamp(0.0, 1.0);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        _ProgressCard(verified: verified, total: total, progress: progress),
        const SizedBox(height: 14),
        ...items
            .map((e) => _StatusRow(item: e))
            .expand((w) => [w, const SizedBox(height: 10)])
            .toList()
          ..removeLast(),
      ],
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.verified,
    required this.total,
    required this.progress,
  });

  final int verified;
  final int total;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.hexFFEEEEEE),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$verified/$total Verified',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: progress,
              backgroundColor: AppColors.hexFFEEEEEE,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.emerald,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.item});

  final DocumentStatusItemModel item;

  @override
  Widget build(BuildContext context) {
    final bool canNavigate =
        item.type == DocumentStatusItemType.aadhaar ||
        item.type == DocumentStatusItemType.pan;

    return GestureDetector(
      onTap: canNavigate ? () => _open(context, item.type) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.hexFFEEEEEE),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(_icon(item.type), color: AppColors.hexFF444444, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.title,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
              ),
            ),
            _StatusBadge(status: item.status),
            if (canNavigate) ...[
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right, color: AppColors.hexFF888888),
            ],
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context, DocumentStatusItemType type) {
    final Widget page = switch (type) {
      DocumentStatusItemType.aadhaar => const AadhaarUploadScreen(),
      DocumentStatusItemType.pan => const PanUploadScreen(),
      _ => const SizedBox.shrink(),
    };
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  IconData _icon(DocumentStatusItemType type) {
    return switch (type) {
      DocumentStatusItemType.profilePhoto => Icons.person_outline_rounded,
      DocumentStatusItemType.dl => Icons.badge_outlined,
      DocumentStatusItemType.rc => Icons.directions_car_outlined,
      DocumentStatusItemType.aadhaar => Icons.credit_card_outlined,
      DocumentStatusItemType.pan => Icons.assignment_ind_outlined,
    };
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.trim().toLowerCase();
    Color bg;
    Color fg;
    String label;
    switch (normalized) {
      case 'verified':
        bg = const Color(0xFFD1FAE5);
        fg = const Color(0xFF065F46);
        label = 'VERIFIED';
        break;
      case 'rejected':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFF991B1B);
        label = 'REJECTED';
        break;
      case 'pending':
      default:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFF92400E);
        label = 'PENDING';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: fg,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(
            Icons.folder_off_outlined,
            size: 48,
            color: AppColors.hexFF888888,
          ),
          SizedBox(height: 14),
          Text(
            'No documents found',
            style: TextStyle(color: AppColors.hexFF888888),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.hexFFEF5350,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.hexFF888888),
            ),
            const SizedBox(height: 18),
            ShadowButton(
              onPressed: () => context.read<DocumentStatusCubit>().load(),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.black,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
