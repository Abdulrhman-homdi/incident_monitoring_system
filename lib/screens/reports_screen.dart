import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/ticket_model.dart';
import '../services/api_service.dart';
import 'ticket_detail_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int _selectedCategory = 0;
  int _selectedStatus = 0;
  List<Ticket> _tickets = [];
  bool _isLoading = true;

  final _categories = [
    'الكل', 'مخالفة بناء', 'نظافة', 'إنارة', 'حفريات', 'تشوه بصري',
  ];

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

  List<_StatusData> get _statuses {
    final counts = <String, int>{};
    for (final t in _tickets) {
      counts[t.status] = (counts[t.status] ?? 0) + 1;
    }
    return [
      _StatusData(label: 'جديد', count: counts['جديد'] ?? 0, color: 0xFF3B82F6),
      _StatusData(label: 'قيد المعالجة', count: counts['قيد المعالجة'] ?? 0, color: 0xFFF59E0B),
      _StatusData(label: 'متأخر', count: counts['متأخر'] ?? 0, color: 0xFFEF4444),
      _StatusData(label: 'مصعد', count: counts['مصعد'] ?? 0, color: 0xFF8B5CF6),
      _StatusData(label: 'منتهي', count: counts['منتهي'] ?? 0, color: 0xFF22C55E),
    ];
  }

  String get _sectionTitle {
    if (_selectedStatus == 0) return 'جميع البلاغات';
    return 'بلاغات ${_statuses[_selectedStatus].label}';
  }

  List<Ticket> get _filteredTickets {
    return _tickets.where((t) {
      if (_selectedCategory > 0 && t.category != _categories[_selectedCategory]) {
        return false;
      }
      if (_selectedStatus > 0 && t.status != _statuses[_selectedStatus].label) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadTickets,
                child: Column(
                  children: [
                    _buildHeader(),
                    _buildCategoryFilter(),
                    _buildStatusCards(),
                    Expanded(child: _buildTicketSection()),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Theme.of(context).cardColor,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: _loadTickets,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B8354).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.refresh,
                    size: 20,
                    color: const Color(0xFF1B8354).withOpacity(0.8),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'البلاغات',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'IBMPlexSansArabic',
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            decoration: InputDecoration(
              hintText: 'ابحث عن البلاغ',
              hintStyle: TextStyle(
                fontFamily: 'IBMPlexSansArabic',
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
              suffixIcon: Icon(
                Icons.search,
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
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
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      color: Theme.of(context).cardColor,
      padding: const EdgeInsets.only(bottom: 16),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final isActive = index == _selectedCategory;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = index),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF1B8354)
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isActive
                          ? const Color(0xFF1B8354)
                          : Theme.of(context).dividerColor,
                    ),
                  ),
                  child: Text(
                    _categories[index],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'IBMPlexSansArabic',
                      color: isActive ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCards() {
    return Container(
      color: Theme.of(context).cardColor,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          children: List.generate(_statuses.length, (index) {
            final status = _statuses[index];
            final isActive = index == _selectedStatus;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedStatus = index),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isActive
                            ? Color(status.color)
                            : Color(status.color).withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: isActive
                            ? Border.all(
                                color: Color(status.color), width: 2)
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        status.count.toString(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'IBMPlexSansArabic',
                          color: isActive
                              ? Colors.white
                              : Color(status.color),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      status.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'IBMPlexSansArabic',
                        color: isActive
                            ? Color(status.color)
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildTicketSection() {
    final filtered = _filteredTickets;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              _sectionTitle,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFamily: 'IBMPlexSansArabic',
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          if (filtered.isEmpty)
            _EmptyState()
          else
            ...filtered.map((t) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _TicketCard(ticket: t),
            )),
        ],
      ),
    );
  }
}

class _StatusData {
  final String label;
  final int count;
  final int color;

  const _StatusData({
    required this.label,
    required this.count,
    required this.color,
  });
}

class _TicketCard extends StatelessWidget {
  final Ticket ticket;

  const _TicketCard({required this.ticket});

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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
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
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(buttons.length, (i) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: i < buttons.length - 1 ? 8 : 0,
                  ),
                  child: OutlinedButton(
                    onPressed: () {
                      if (buttons[i] == 'تفاصيل البلاغ') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TicketDetailScreen(ticket: ticket),
                          ),
                        );
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      foregroundColor: const Color(0xFF1B8354),
                      side: BorderSide(color: Theme.of(context).dividerColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: Text(
                      buttons[i],
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
