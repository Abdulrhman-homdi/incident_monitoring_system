import 'package:flutter/material.dart';
import 'message_screen.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  int _selectedFilter = 0;

  final _chats = [
    _ChatData(
      title: 'مجموعة التفتيش ج',
      message: 'احمد القحطاني : تمام ما عندك مشكلة',
      time: 'منذ ١٠ دقائق',
      badge: '١٠',
      avatarColors: [0xFF2D9373, 0xFF00a651],
    ),
    _ChatData(
      title: 'مجموعة أ',
      message: 'ناصر المهري : ان شاء الله على خير',
      time: '١٤٤٧/٦/١٢',
      badge: '٢٢',
      avatarColors: [0xFF2563EB, 0xFF3B82F6],
    ),
    _ChatData(
      title: 'مجموعة و',
      message: 'صقر الغامدي : انتهى ان شاء الله',
      time: '١٤٤٧/٦/١',
      avatarColors: [0xFF7C3AED, 0xFF8B5CF6],
    ),
    _ChatData(
      title: 'مجموعة ب',
      message: 'عبد الله خالد السلام عليكم اجتماعنا الس....',
      time: '١٤٤٧/٦/١',
      avatarColors: [0xFFDC2626, 0xFFEF4444],
    ),
    _ChatData(
      title: 'مجموعة هـ',
      message: 'ماجد عبدالله جزاكم الله خير جميعا',
      time: '١٤٤٧/٦/١',
      avatarColors: [0xFFD97706, 0xFFF59E0B],
    ),
    _ChatData(
      title: 'مجموعة ج',
      message: 'عمر قاضي : طلع عندي البلاغ',
      time: '١٤٤٧/٦/١',
      avatarColors: [0xFF0891B2, 0xFF06B6D4],
    ),
    _ChatData(
      title: 'مجموعة د',
      message: 'فاروق محمد ابشر',
      time: '١٤٤٧/٦/١',
      avatarColors: [0xFFBE185D, 0xFFEC4899],
    ),
    _ChatData(
      title: 'مجموعة ا',
      message: 'حمد زايد استاذ صقر يعطيك العافية',
      time: '١٤٤٧/٦/١',
      avatarColors: [0xFF15803D, 0xFF22C55E],
    ),
    _ChatData(
      title: 'مجموعة ٢',
      message: 'صقر الغامدي: انتهى',
      time: '١٤٤٧/٦/١',
      avatarColors: [0xFF6B7280, 0xFF9CA3AF],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            const _SearchBar(),
            _FilterTabs(
              selected: _selectedFilter,
              onChanged: (i) => setState(() => _selectedFilter = i),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _chats.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: Theme.of(context).dividerColor,
                ),
                itemBuilder: (context, index) {
                  final chat = _chats[index];
                  final show =
                      _selectedFilter == 0 ? chat.badge != null : chat.badge == null;
                  if (!show) return const SizedBox.shrink();
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MessageScreen(
                          groupTitle: chat.title,
                          avatarColors: chat.avatarColors,
                        ),
                      ),
                    ),
                    child: _ChatItem(chat: chat),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatData {
  final String title;
  final String message;
  final String time;
  final String? badge;
  final List<int> avatarColors;

  const _ChatData({
    required this.title,
    required this.message,
    required this.time,
    this.badge,
    required this.avatarColors,
  });
}

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).cardColor,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
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
          suffixIcon: Icon(
            Icons.search,
            color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
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

class _FilterTabs extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;

  const _FilterTabs({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).cardColor,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          children: [
            _FilterButton(
              label: 'غير المقروء',
              isActive: selected == 0,
              onTap: () => onChanged(0),
            ),
            const SizedBox(width: 12),
            _FilterButton(
              label: 'المقروء',
              isActive: selected == 1,
              onTap: () => onChanged(1),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF2D9373) : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: 'IBMPlexSansArabic',
            color: isActive ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _ChatItem extends StatelessWidget {
  final _ChatData chat;

  const _ChatItem({required this.chat});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Avatar(
              initials: _initials(chat.title),
              colors: chat.avatarColors,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Text(
                        chat.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'IBMPlexSansArabic',
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        chat.time,
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'IBMPlexSansArabic',
                          color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (chat.badge != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2D9373),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(minWidth: 20),
                          child: Text(
                            chat.badge!,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              fontFamily: 'IBMPlexSansArabic',
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      if (chat.badge != null) const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          chat.message,
                          style: TextStyle(
                            fontSize: 13,
                            fontFamily: 'IBMPlexSansArabic',
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String title) {
    final parts = title.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}';
    }
    return title.isNotEmpty ? title[0] : '?';
  }
}

class _Avatar extends StatelessWidget {
  final String initials;
  final List<int> colors;

  const _Avatar({
    required this.initials,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: colors.map((c) => Color(c)).toList(),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          fontFamily: 'IBMPlexSansArabic',
        ),
      ),
    );
  }
}
