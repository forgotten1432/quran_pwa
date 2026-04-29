import 'package:flutter/material.dart';
import '../data/quran_index.dart';

class QuranNavigationDrawer extends StatefulWidget {
  final Function(int page) onPageSelected;
  final int currentPage;

  const QuranNavigationDrawer({
    super.key,
    required this.onPageSelected,
    required this.currentPage,
  });

  @override
  State<QuranNavigationDrawer> createState() => _QuranNavigationDrawerState();
}

class _QuranNavigationDrawerState extends State<QuranNavigationDrawer>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Drawer(
      child: Column(
        children: [
          _buildHeader(theme, isDark),
          TabBar(
            controller: _tabController,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurface.withAlpha(150),
            indicatorColor: theme.colorScheme.primary,
            indicatorWeight: 3,
            tabs: const [
              Tab(text: 'السور', icon: Icon(Icons.menu_book, size: 20)),
              Tab(text: 'الأجزاء', icon: Icon(Icons.bookmark, size: 20)),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSurahList(theme),
                _buildJuzList(theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        bottom: 16,
        left: 20,
        right: 20,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF2A2A2A), const Color(0xFF1A1A1A)]
              : [const Color(0xFF1B5E20), const Color(0xFF2E7D32)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '📖',
            style: TextStyle(fontSize: 36),
          ),
          const SizedBox(height: 8),
          Text(
            'فهرس القرآن الكريم',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFFD4A853) : Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'صفحة ${widget.currentPage} من 604',
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? Colors.grey.shade400
                  : Colors.white.withAlpha(200),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurahList(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: QuranIndex.surahs.length,
      itemBuilder: (context, index) {
        final surah = QuranIndex.surahs[index];
        final isCurrentSurah = _isCurrentSurah(surah, index);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isCurrentSurah
                ? theme.colorScheme.primary.withAlpha(25)
                : null,
          ),
          child: ListTile(
            dense: true,
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.primary.withAlpha(100),
                  width: 1.5,
                ),
                color: isCurrentSurah
                    ? theme.colorScheme.primary.withAlpha(40)
                    : Colors.transparent,
              ),
              alignment: Alignment.center,
              child: Text(
                '${surah.number}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            title: Text(
              surah.nameArabic,
              style: TextStyle(
                fontSize: 18,
                fontWeight: isCurrentSurah ? FontWeight.bold : FontWeight.w500,
                color: isCurrentSurah
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
              ),
              textDirection: TextDirection.rtl,
            ),
            subtitle: Text(
              surah.nameEnglish,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withAlpha(150),
              ),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: theme.colorScheme.primary.withAlpha(20),
              ),
              child: Text(
                'ص ${surah.page}',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            onTap: () {
              widget.onPageSelected(surah.page);
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }

  Widget _buildJuzList(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: QuranIndex.juzList.length,
      itemBuilder: (context, index) {
        final juz = QuranIndex.juzList[index];
        final isCurrentJuz = _isCurrentJuz(juz, index);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isCurrentJuz
                ? theme.colorScheme.primary.withAlpha(25)
                : null,
          ),
          child: ListTile(
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withAlpha(180),
                    theme.colorScheme.primary,
                  ],
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                '${juz.number}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            title: Text(
              'الجزء ${juz.number}',
              style: TextStyle(
                fontSize: 17,
                fontWeight: isCurrentJuz ? FontWeight.bold : FontWeight.w500,
                color: isCurrentJuz
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
              ),
              textDirection: TextDirection.rtl,
            ),
            subtitle: Text(
              juz.nameArabic,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withAlpha(150),
              ),
              textDirection: TextDirection.rtl,
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: theme.colorScheme.primary.withAlpha(20),
              ),
              child: Text(
                'ص ${juz.page}',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            onTap: () {
              widget.onPageSelected(juz.page);
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }

  bool _isCurrentSurah(SurahInfo surah, int index) {
    final nextPage = index < QuranIndex.surahs.length - 1
        ? QuranIndex.surahs[index + 1].page
        : 605;
    return widget.currentPage >= surah.page && widget.currentPage < nextPage;
  }

  bool _isCurrentJuz(JuzInfo juz, int index) {
    final nextPage = index < QuranIndex.juzList.length - 1
        ? QuranIndex.juzList[index + 1].page
        : 605;
    return widget.currentPage >= juz.page && widget.currentPage < nextPage;
  }
}
