import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/ticket_model.dart';
import '../services/api_service.dart';

class TicketDetailScreen extends StatefulWidget {
  final Ticket ticket;
  final bool isGuest;

  const TicketDetailScreen({
    super.key,
    required this.ticket,
    this.isGuest = false,
  });

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  late Ticket _ticket;
  bool _actionLoading = false;
  final TextEditingController _assigneeController = TextEditingController();
  final TextEditingController _inquiryController = TextEditingController();

  final List<String> _escalateReasons = [
    'خارج الصلاحية', 'خطورة عالية', 'دعم قانوني', 'دعم أمني',
    'موارد إضافية', 'تكرار عالي', 'تعارض مصالح', 'أخرى',
  ];

  @override
  void initState() {
    super.initState();
    _ticket = widget.ticket;
  }

  @override
  void dispose() {
    _assigneeController.dispose();
    _inquiryController.dispose();
    super.dispose();
  }

  Future<void> _handleAction(String action, {String details = '', String assignee = '', String escalationReason = '', String targetEntity = ''}) async {
    setState(() => _actionLoading = true);
    try {
      final updated = await ApiService.performAction(
        id: _ticket.id,
        action: action,
        details: details,
        assignee: assignee,
        escalationReason: escalationReason,
        targetEntity: targetEntity,
      );
      if (mounted) {
        setState(() => _ticket = updated);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم تنفيذ الإجراء "$action" بنجاح')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل تنفيذ الإجراء: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  void _showAssigneePopup() {
    _assigneeController.clear();
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تعيين مسؤول'),
          content: TextField(
            controller: _assigneeController,
            decoration: const InputDecoration(
              hintText: 'اسم المسؤول',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () {
                if (_assigneeController.text.trim().isNotEmpty) {
                  Navigator.pop(ctx);
                  _handleAction('تعيين', assignee: _assigneeController.text.trim());
                }
              },
              child: const Text('تأكيد'),
            ),
          ],
        ),
      ),
    );
  }

  void _showInquiryPopup() {
    _inquiryController.clear();
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('إرسال استفسار'),
          content: TextField(
            controller: _inquiryController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'نص الاستفسار',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () {
                if (_inquiryController.text.trim().isNotEmpty) {
                  Navigator.pop(ctx);
                  _handleAction('استفسار', details: _inquiryController.text.trim());
                }
              },
              child: const Text('إرسال'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEscalatePopup() {
    showDialog(
      context: context,
      builder: (ctx) {
        String selectedReason = '';
        final entityController = TextEditingController();
        return Directionality(
          textDirection: TextDirection.rtl,
          child: StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
              title: const Text('تصعيد البلاغ'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('سبب التصعيد', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedReason.isEmpty ? null : selectedReason,
                    decoration: const InputDecoration(
                      hintText: 'اختر السبب',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    items: _escalateReasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                    onChanged: (v) => setDialogState(() => selectedReason = v ?? ''),
                  ),
                  const SizedBox(height: 16),
                  const Text('الجهة المصعد لها', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: entityController,
                    decoration: const InputDecoration(
                      hintText: 'اسم الجهة',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (selectedReason.isNotEmpty && entityController.text.trim().isNotEmpty) {
                      Navigator.pop(ctx);
                      _handleAction('تصعيد',
                        escalationReason: selectedReason,
                        targetEntity: entityController.text.trim(),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('تصعيد'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = Ticket.colorForStatus(_ticket.status);
    final loc = _ticket.location;
    final progress = _ticket.progressLog;
    final isCompleted = _ticket.status == 'منتهي';
    final isNew = _ticket.status == 'جديد';
    final isInProgress = _ticket.status == 'قيد المعالجة';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'تفاصيل البلاغ',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: 'IBMPlexSansArabic',
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_forward_ios, color: Theme.of(context).colorScheme.onSurface, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (_ticket.imageUrl.isNotEmpty)
                    Container(
                      width: double.infinity,
                      height: 280,
                      decoration: BoxDecoration(
                        color: Theme.of(context).dividerColor,
                        image: DecorationImage(
                          image: NetworkImage(_ticket.imageUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const SizedBox(height: 20),
                        _buildHeader(statusColor),
                        const SizedBox(height: 20),
                        _buildDescription(),
                        const SizedBox(height: 20),
                        _buildLocation(loc),
                        const SizedBox(height: 20),
                        _buildProgressTimeline(progress),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (!widget.isGuest && !isCompleted)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildActionBar(isNew, isInProgress),
              ),
            if (_actionLoading)
              Container(
                color: Colors.black26,
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Color statusColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          _ticket.title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            fontFamily: 'IBMPlexSansArabic',
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _ticket.ticketId,
          style: TextStyle(
            fontSize: 13,
            fontFamily: 'IBMPlexSansArabic',
            color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _ticket.category,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'IBMPlexSansArabic',
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _ticket.status,
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
      ],
    );
  }

  Widget _buildDescription() {
    return Container(
      width: double.infinity,
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
          Text(
            'وصف البلاغ',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              fontFamily: 'IBMPlexSansArabic',
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _ticket.description.isNotEmpty
                ? _ticket.description
                : 'لا توجد تفاصيل إضافية لهذا البلاغ.',
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'IBMPlexSansArabic',
              color: _ticket.description.isNotEmpty
                  ? Theme.of(context).colorScheme.onSurface
                  : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocation(TicketLocation? loc) {
    final hasCoords = loc != null && loc.lat != 0 && loc.lng != 0;
    final hasAnyInfo = loc != null && (loc.address.isNotEmpty || loc.district.isNotEmpty || loc.landmark.isNotEmpty);

    return Container(
      width: double.infinity,
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
          Text(
            'موقع البلاغ',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              fontFamily: 'IBMPlexSansArabic',
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          if (hasCoords)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 200,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(loc.lat, loc.lng),
                    initialZoom: 15,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.balady.app',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(loc.lat, loc.lng),
                          width: 40,
                          height: 40,
                          child: Icon(
                            Icons.location_on,
                            color: Theme.of(context).colorScheme.primary,
                            size: 36,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  'لا توجد إحداثيات للموقع',
                  style: TextStyle(
                    fontSize: 13,
                    fontFamily: 'IBMPlexSansArabic',
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          if (hasAnyInfo) ...[
            const SizedBox(height: 12),
            _infoRow('العنوان', loc.address),
            _infoRow('الحي', loc.district),
            _infoRow('الإحداثيات', '${loc.lat}, ${loc.lng}'),
            _infoRow('معلم قريب', loc.landmark),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              value,
              textDirection: TextDirection.ltr,
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'IBMPlexSansArabic',
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: 'IBMPlexSansArabic',
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressTimeline(List<ProgressEntry> progress) {
    return Container(
      width: double.infinity,
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
          Text(
            'سجل التقدم',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              fontFamily: 'IBMPlexSansArabic',
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          if (progress.isEmpty)
            Center(
              child: Text(
                'لا يوجد سجل تقدم بعد',
                style: TextStyle(
                  fontSize: 13,
                  fontFamily: 'IBMPlexSansArabic',
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ),
            )
          else
            ...List.generate(progress.length, (i) {
              final entry = progress[i];
              final isLast = i == progress.length - 1;
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              entry.action,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'IBMPlexSansArabic',
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            if (entry.details.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  entry.details,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'IBMPlexSansArabic',
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            if (entry.assignee.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  'المسؤول: ${entry.assignee}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontFamily: 'IBMPlexSansArabic',
                                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                  ),
                                ),
                              ),
                            if (entry.createdAt != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  _formatDate(entry.createdAt!),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontFamily: 'IBMPlexSansArabic',
                                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 24,
                      child: Column(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            margin: const EdgeInsets.only(top: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isLast
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                            ),
                          ),
                          if (!isLast)
                            Expanded(
                              child: Container(
                                width: 2,
                                color: Theme.of(context).dividerColor,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildActionBar(bool isNew, bool isInProgress) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              if (isInProgress)
                _actionButton(
                  label: 'إنهاء',
                  icon: Icons.check_circle_outline,
                  color: const Color(0xFF16A34A),
                  onTap: () => _handleAction('إنهاء'),
                ),
              if (isNew)
                _actionButton(
                  label: 'مباشرة',
                  icon: Icons.bolt,
                  color: const Color(0xFFF59E0B),
                  onTap: () => _handleAction('مباشرة'),
                ),
              if (isNew || isInProgress)
                _actionButton(
                  label: 'تصعيد',
                  icon: Icons.vertical_align_top,
                  color: const Color(0xFF7C3AED),
                  onTap: _showEscalatePopup,
                ),
              _actionButton(
                label: 'تعيين',
                icon: Icons.person_add,
                color: const Color(0xFF2563EB),
                onTap: _showAssigneePopup,
              ),
              _actionButton(
                label: 'استفسار',
                icon: Icons.help_outline,
                color: const Color(0xFF6B7280),
                onTap: _showInquiryPopup,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Material(
        borderRadius: BorderRadius.circular(12),
        color: color.withValues(alpha: 0.1),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'IBMPlexSansArabic',
                    color: color,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(icon, size: 18, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final y = dt.year.toString();
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$y/$m/$d $h:$min';
  }
}
