import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goapp/core/di/injection.dart';
import 'package:goapp/core/theme/app_colors.dart';
import 'package:goapp/core/widgets/app_app_bar.dart';
import 'package:goapp/core/widgets/shadow_button.dart';
import 'package:goapp/features/documents/document_details/presentation/cubit/document_details_cubit.dart';
import 'package:goapp/features/documents/document_details/presentation/cubit/document_details_state.dart';
import 'package:goapp/features/documents/document_details/presentation/model/document_card_model.dart';

class DocumentDetailsScreen extends StatelessWidget {
  const DocumentDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DocumentDetailsCubit>(
      create: (_) => sl<DocumentDetailsCubit>()..load(),
      child: const _DocumentDetailsView(),
    );
  }
}

class _DocumentDetailsView extends StatelessWidget {
  const _DocumentDetailsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: const AppAppBar(title: 'Document Details'),
      body: BlocBuilder<DocumentDetailsCubit, DocumentDetailsState>(
        builder: (context, state) {
          if (state is DocumentDetailsLoading ||
              state is DocumentDetailsInitial) {
            return const _LoadingView();
          }
          if (state is DocumentDetailsError) {
            return _ErrorView(message: state.message);
          }
          if (state is DocumentDetailsLoaded) {
            if (state.isEmpty) {
              return const _EmptyView();
            }
            return _LoadedView(aadhaar: state.aadhaar, pan: state.pan);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _LoadedView extends StatelessWidget {
  const _LoadedView({required this.aadhaar, required this.pan});

  final DocumentCardModel? aadhaar;
  final DocumentCardModel? pan;

  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[
      _DocumentCard(card: aadhaar, emptyTitle: 'Aadhaar'),
      const SizedBox(height: 14),
      _DocumentCard(card: pan, emptyTitle: 'PAN'),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: cards,
    );
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({required this.card, required this.emptyTitle});

  final DocumentCardModel? card;
  final String emptyTitle;

  @override
  Widget build(BuildContext context) {
    final bool isEmpty = card == null;
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
          Row(
            children: [
              Text(
                isEmpty ? emptyTitle : card!.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                ),
              ),
              const Spacer(),
              if (!isEmpty) _StatusBadge(status: card!.status),
            ],
          ),
          const SizedBox(height: 10),
          if (isEmpty)
            Text(
              'Document not uploaded',
              style: TextStyle(color: AppColors.hexFF888888),
            )
          else ...[
            Text(
              card!.numberMasked,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.black,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              card!.uploadedDate.isEmpty
                  ? ''
                  : 'Uploaded: ${card!.uploadedDate}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.hexFF888888,
              ),
            ),
            const SizedBox(height: 12),
            _PreviewBox(imageUrl: card!.imageUrl),
          ],
        ],
      ),
    );
  }
}

class _PreviewBox extends StatelessWidget {
  const _PreviewBox({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.hexFFF5F5F5,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.hexFFEEEEEE),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: imageUrl.trim().isEmpty
            ? const _EmptyPreview()
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) =>
                    const _EmptyPreview(),
              ),
      ),
    );
  }
}

class _EmptyPreview extends StatelessWidget {
  const _EmptyPreview();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.image_not_supported_outlined, size: 34),
          SizedBox(height: 8),
          Text(
            'Preview unavailable',
            style: TextStyle(color: AppColors.hexFF888888),
          ),
        ],
      ),
    );
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
    switch (normalized) {
      case 'approved':
        bg = const Color(0xFFD1FAE5);
        fg = const Color(0xFF065F46);
        break;
      case 'rejected':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFF991B1B);
        break;
      case 'pending':
      default:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFF92400E);
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        normalized.isEmpty ? 'pending' : normalized,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: const [_SkeletonCard(), SizedBox(height: 14), _SkeletonCard()],
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
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  late final Animation<double> _anim = Tween<double>(
    begin: -1.4,
    end: 1.4,
  ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));

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
          height: 220,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
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
            'Document not uploaded',
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
              onPressed: () => context.read<DocumentDetailsCubit>().load(),
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
