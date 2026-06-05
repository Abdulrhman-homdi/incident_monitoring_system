import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/ticket_model.dart';
import '../services/api_service.dart';
import '../core/app_theme.dart';
import 'ticket_detail_screen.dart';
import 'process_ticket_screen.dart';

class HomeScreen extends StatefulWidget {
  final bool isGuest;

  const HomeScreen({super.key, this.isGuest = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Ticket> _tickets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    try {
      final tickets = await ApiService.fetchTickets();
      if (mounted) {
        setState(() {
          _tickets = tickets;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeTickets = _tickets.where((t) => t.status != 'منتهي').toList();
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    _BrandHeader(onRefresh: _loadTickets),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadTickets,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Column(
                            children: [
                              const _SearchBar(),
                              _KpiSection(totalTickets: activeTickets.length),
                              _StatusCarousel(tickets: activeTickets),
                              _RecentTickets(tickets: activeTickets, isGuest: widget.isGuest),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  final VoidCallback? onRefresh;

  const _BrandHeader({this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      color: Theme.of(context).cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'اسم الأمانة باللغة العربية',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'IBMPlexSansArabic',
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Name of Municipality in English',
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'IBMPlexSansArabic',
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: onRefresh,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.refresh,
                        size: 22,
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 48,
                    height: 48,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Image.asset(
                      Theme.of(context).brightness == Brightness.dark
                          ? 'assets/images/icon_dark.png'
                          : 'assets/images/icon_light.png',
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: Theme.of(context).colorScheme.surfaceContainerHighest),
          const SizedBox(height: 12),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'مرحبا بك مره اخرى',
                    style: TextStyle(
                      fontSize: 13,
                      fontFamily: 'IBMPlexSansArabic',
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    'م. تركي بن عبدالرحمن',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'IBMPlexSansArabic',
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Icon(Icons.waving_hand, size: 20, color: AppColors.statusInProgress),
              const SizedBox(width: 8),
            ],
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).cardColor,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: TextField(
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
        decoration: InputDecoration(
          hintText: 'ابحث عن البلاغ',
          hintStyle: TextStyle(
            fontFamily: 'IBMPlexSansArabic',
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          suffixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
          filled: true,
          fillColor: Theme.of(context).cardColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Theme.of(context).dividerColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Theme.of(context).dividerColor),
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 16,
          ),
        ),
      ),
    );
  }
}

class _KpiSection extends StatelessWidget {
  final int totalTickets;

  const _KpiSection({this.totalTickets = 0});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      color: Theme.of(context).cardColor,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Row(
        children: [
          Expanded(
            child: _KpiCard(
              title: 'متوسط وقت الاستجابة الأسبوعي',
              value: '5.2',
              unit: 'يوم',
              footer: 'من $totalTickets بلاغ',
              color: primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _KpiCard(
              title: 'معدل الإغلاق اليومي',
              value: '52',
              unit: '%',
              footer: 'من $totalTickets بلاغ',
              color: primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final String footer;
  final Color color;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.footer,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'IBMPlexSansArabic',
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                unit,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'IBMPlexSansArabic',
                  color: color,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'IBMPlexSansArabic',
                  color: color,
                  height: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            footer,
            style: TextStyle(
              fontSize: 11,
              fontFamily: 'IBMPlexSansArabic',
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCarousel extends StatelessWidget {
  final List<Ticket> tickets;

  const _StatusCarousel({required this.tickets});

  List<_StatusBadgeData> get _statuses {
    final counts = <String, int>{};
    for (final t in tickets) {
      counts[t.status] = (counts[t.status] ?? 0) + 1;
    }
    return [
      _StatusBadgeData(label: 'جديد', count: counts['جديد'] ?? 0, color: AppColors.statusNew),
      _StatusBadgeData(label: 'قيد المعالجة', count: counts['قيد المعالجة'] ?? 0, color: AppColors.statusInProgress),
      _StatusBadgeData(label: 'متأخر', count: counts['متأخر'] ?? 0, color: AppColors.statusDelayed),
      _StatusBadgeData(label: 'مصعد', count: counts['مصعد'] ?? 0, color: AppColors.statusEscalated),
      _StatusBadgeData(label: 'منتهي', count: counts['منتهي'] ?? 0, color: AppColors.statusCompleted),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).cardColor,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          children: _statuses
              .map((s) => Expanded(
                    child: _StatusBadge(data: s),
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class _StatusBadgeData {
  final String label;
  final int count;
  final Color color;

  const _StatusBadgeData({
    required this.label,
    required this.count,
    required this.color,
  });
}

class _StatusBadge extends StatelessWidget {
  final _StatusBadgeData data;

  const _StatusBadge({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: data.color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            data.count.toString(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              fontFamily: 'IBMPlexSansArabic',
              color: data.color,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          data.label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            fontFamily: 'IBMPlexSansArabic',
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _RecentTickets extends StatelessWidget {
  final List<Ticket> tickets;
  final bool isGuest;

  const _RecentTickets({required this.tickets, this.isGuest = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'اخر البلاغات',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFamily: 'IBMPlexSansArabic',
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            if (tickets.isEmpty)
              _EmptyState()
            else
              ...tickets.map((t) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _TicketCard(ticket: t, isGuest: isGuest),
                  )),
          ],
        ),
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final Ticket ticket;
  final bool isGuest;

  const _TicketCard({required this.ticket, this.isGuest = false});

  @override
  Widget build(BuildContext context) {
    final statusColor = Ticket.colorForStatus(ticket.status);
    final buttons = Ticket.buttonsForStatus(ticket.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: ticket.imageUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: ticket.imageUrl.startsWith('data:')
                            ? Image.memory(
                                _base64Decode(ticket.imageUrl),
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                              )
                            : Image.network(
                                ticket.imageUrl,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                              ),
                      )
                    : Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Theme.of(context).dividerColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            size: 24,
                            color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      ticket.ticketId,
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'IBMPlexSansArabic',
                        color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ticket.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'IBMPlexSansArabic',
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              ticket.status,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'IBMPlexSansArabic',
                color: statusColor,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(isGuest ? 1 : buttons.length, (i) {
              final label = isGuest ? 'تفاصيل البلاغ' : buttons[i];
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: i < (isGuest ? 1 : buttons.length) - 1 ? 8 : 0,
                  ),
                  child: OutlinedButton(
                    onPressed: () {
                      if (label == 'تفاصيل البلاغ' || label == 'عرض تفاصيل البلاغ' || label == 'متابعة الإجراءات' || label == 'متابعة حالة التصعيد') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TicketDetailScreen(ticket: ticket, isGuest: isGuest),
                          ),
                        );
                      } else if (label == 'مباشرة البلاغ' || label == 'مباشرة حالا') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProcessTicketScreen(ticket: ticket, isGuest: isGuest),
                          ),
                        );
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      side: BorderSide(color: Theme.of(context).dividerColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'IBMPlexSansArabic',
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '🎉',
            style: TextStyle(fontSize: 48),
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد بلاغات جديدة حالياً',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: 'IBMPlexSansArabic',
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'تم الانتهاء من جميع البلاغات، وسيتم إشعارك فور ورود بلاغ جديد.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontFamily: 'IBMPlexSansArabic',
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

dynamic _base64Decode(String dataUrl) {
  final parts = dataUrl.split(',');
  if (parts.length > 1) {
    return base64Decode(parts[1]);
  }
  return base64Decode(dataUrl);
}
