import 'package:flutter/material.dart';
import 'package:goapp/core/theme/app_colors.dart';
import 'package:goapp/core/widgets/app_app_bar.dart';
import 'package:goapp/features/help_support/presentation/pages/ticket_tracking_detail_screen.dart';

class TicketTrackingScreen extends StatefulWidget {
  const TicketTrackingScreen({super.key});

  @override
  State<TicketTrackingScreen> createState() => _TicketTrackingScreenState();
}

enum _TicketUiStatus { open, resolved }

class _TicketTrackingScreenState extends State<TicketTrackingScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static final List<_TicketUiModel> _allTickets = <_TicketUiModel>[
    _TicketUiModel(
      categoryTitle: 'Rider Behavior',
      ticketCode: 'TK-98220',
      timestampLabel: 'Feb 24, 09:30 AM',
      status: _TicketUiStatus.open,
      snippet: 'The Rider to rude and he not pay...',
      group: _TicketGroup.recent,
      details: TicketTrackingDetailModel.paymentIssueExample(),
    ),
    _TicketUiModel(
      categoryTitle: 'App Crash on Checkout',
      ticketCode: 'TK-98219',
      timestampLabel: 'Feb 23, 10:48 AM',
      status: _TicketUiStatus.resolved,
      snippet: 'App closes automatically when I...',
      group: _TicketGroup.yesterday,
      details: TicketTrackingDetailModel.paymentIssueExample(
        statusLabel: 'RESOLVED',
        statusPillColor: AppColors.hex1A00A86B,
        statusTextColor: AppColors.hexFF00A86B,
      ),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tickets = _filteredTicketsForTab(_tabController.index);
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppAppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: AppColors.textBody),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: const Text('Tickets Tracking', style: TextStyle(fontSize: 18)),
        backgroundColor: AppColors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                onTap: (_) => setState(() {}),
                indicator: const UnderlineTabIndicator(
                  borderSide: BorderSide(color: AppColors.emerald, width: 2.5),
                  insets: EdgeInsets.symmetric(horizontal: 28),
                ),
                dividerColor: Colors.transparent,
                dividerHeight: 0,
                labelColor: AppColors.textBody,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Open/In Progress'),
                  Tab(text: 'Resolved'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        children: [
          if (tickets.any((t) => t.group == _TicketGroup.recent)) ...[
            const _SectionLabel(text: 'RECENT TICKETS'),
            const SizedBox(height: 10),
            ...tickets
                .where((t) => t.group == _TicketGroup.recent)
                .map((t) => _TicketCard(ticket: t)),
            const SizedBox(height: 18),
          ],
          if (tickets.any((t) => t.group == _TicketGroup.yesterday)) ...[
            const _SectionLabel(text: 'YESTERDAY'),
            const SizedBox(height: 10),
            ...tickets
                .where((t) => t.group == _TicketGroup.yesterday)
                .map((t) => _TicketCard(ticket: t)),
          ],
        ],
      ),
    );
  }

  List<_TicketUiModel> _filteredTicketsForTab(int index) {
    switch (index) {
      case 1:
        return _allTickets
            .where((t) => t.status == _TicketUiStatus.open)
            .toList(growable: false);
      case 2:
        return _allTickets
            .where((t) => t.status == _TicketUiStatus.resolved)
            .toList(growable: false);
      case 0:
      default:
        return _allTickets;
    }
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 0.8,
      ),
    );
  }
}

enum _TicketGroup { recent, yesterday }

class _TicketUiModel {
  const _TicketUiModel({
    required this.categoryTitle,
    required this.ticketCode,
    required this.timestampLabel,
    required this.status,
    required this.snippet,
    required this.group,
    required this.details,
  });

  final String categoryTitle;
  final String ticketCode;
  final String timestampLabel;
  final _TicketUiStatus status;
  final String snippet;
  final _TicketGroup group;
  final TicketTrackingDetailModel details;
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.ticket});

  final _TicketUiModel ticket;

  @override
  Widget build(BuildContext context) {
    final isOpen = ticket.status == _TicketUiStatus.open;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    TicketTrackingDetailScreen(model: ticket.details),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderSoft),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              ticket.categoryTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textBody,
                              ),
                            ),
                          ),
                          _StatusPill(
                            label: isOpen ? 'OPEN' : 'RESOLVED',
                            background: isOpen
                                ? AppColors.hex3325C59A
                                : const Color(0xFFFFEDED),
                            text: isOpen
                                ? AppColors.hexFF0EA271
                                : AppColors.red,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '#${ticket.ticketCode}  •  ${ticket.timestampLabel}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        ticket.snippet,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.background,
    required this.text,
  });

  final String label;
  final Color background;
  final Color text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: text,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
