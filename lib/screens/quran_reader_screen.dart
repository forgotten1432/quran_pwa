import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/quran_index.dart';
import '../services/preferences_service.dart';
import '../widgets/navigation_drawer.dart';
import '../widgets/go_to_page_dialog.dart';

class ZoomablePage extends StatefulWidget {
  final Widget child;
  const ZoomablePage({Key? key, required this.child}) : super(key: key);

  @override
  State<ZoomablePage> createState() => _ZoomablePageState();
}

class _ZoomablePageState extends State<ZoomablePage> {
  final TransformationController _controller = TransformationController();
  bool _panEnabled = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      // 1.0 is the default scale. We add a tiny threshold.
      final isZoomed = _controller.value.getMaxScaleOnAxis() > 1.01;
      if (_panEnabled != isZoomed) {
        setState(() {
          _panEnabled = isZoomed;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      transformationController: _controller,
      panEnabled: _panEnabled,
      scaleEnabled: true,
      maxScale: 4.0,
      minScale: 1.0,
      child: widget.child,
    );
  }
}

class QuranReaderScreen extends StatefulWidget {
  final PreferencesService prefsService;
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  const QuranReaderScreen({
    super.key,
    required this.prefsService,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  @override
  State<QuranReaderScreen> createState() => _QuranReaderScreenState();
}

class _QuranReaderScreenState extends State<QuranReaderScreen>
    with TickerProviderStateMixin {
  int _currentPage = 1;
  int _totalPages = 608; // 607 original + 1 blank page for missing page 101
  bool _isFullscreen = false;
  bool _showControls = true;
  Timer? _hideTimer;
  late AnimationController _fadeController;
  
  PageController? _pageController;
  bool? _lastIsPortrait;

  @override
  void initState() {
    super.initState();
    // Clear image cache and limit it to avoid high RAM usage
    PaintingBinding.instance.imageCache.maximumSize = 10;
    PaintingBinding.instance.imageCache.maximumSizeBytes = 20 * 1024 * 1024; // 20 MB

    _currentPage = widget.prefsService.getLastPage();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1.0,
    );
    _startHideTimer();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
    ));
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _fadeController.dispose();
    _pageController?.dispose();
    super.dispose();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _showControls) {
        setState(() => _showControls = false);
        _fadeController.reverse();
      }
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) {
      _fadeController.forward();
      _startHideTimer();
    } else {
      _fadeController.reverse();
    }
  }

  void _goToPage(int page) {
    if (page >= 1 && page <= _totalPages) {
      setState(() => _currentPage = page);
      widget.prefsService.saveLastPage(page);
      
      if (_pageController?.hasClients == true && _lastIsPortrait != null) {
        final targetIndex = _lastIsPortrait! ? page - 1 : (page - 1) ~/ 2;
        _pageController!.jumpToPage(targetIndex);
      } else if (_lastIsPortrait != null) {
        final initialIndex = _lastIsPortrait! ? page - 1 : (page - 1) ~/ 2;
        _pageController?.dispose();
        _pageController = PageController(initialPage: initialIndex);
      }
    }
  }

  void _toggleFullscreen() {
    setState(() => _isFullscreen = !_isFullscreen);
    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  Future<void> _showGoToPageDialog() async {
    final page = await showDialog<int>(
      context: context,
      builder: (ctx) => GoToPageDialog(
        currentPage: _currentPage,
        totalPages: _totalPages,
      ),
    );
    if (page != null) {
      _goToPage(page);
    }
  }

  String _getCurrentSurahName() {
    String name = QuranIndex.surahs[0].nameArabic;
    for (int i = QuranIndex.surahs.length - 1; i >= 0; i--) {
      if (_currentPage >= QuranIndex.surahs[i].page) {
        name = QuranIndex.surahs[i].nameArabic;
        break;
      }
    }
    return name;
  }

  // Returns an Image.network for the page or a blank Container if it's the missing page 101
  Widget _buildImagePage(int virtualPageNumber, ThemeData theme) {
    if (virtualPageNumber == 101) {
      return Container(
        color: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        child: const Center(
          child: Text(
            'Eksik Sayfa',
            style: TextStyle(color: Colors.grey, fontSize: 18),
          ),
        ),
      );
    }

    final realPageNumber = virtualPageNumber;
    
    // Bounds check
    if (realPageNumber < 1 || realPageNumber > 608) {
      return const SizedBox();
    }

    final imageUrl = 'pages/page-${realPageNumber.toString().padLeft(3, '0')}.jpg';

    return Container(
      decoration: BoxDecoration(
        color: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Image.network(
        imageUrl,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              color: theme.colorScheme.primary,
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes ?? 1)
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(Icons.error_outline, size: 40, color: Colors.grey),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final safePadding = mediaQuery.padding;

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      backgroundColor: widget.isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F0E8),
      appBar: _isFullscreen
          ? null
          : _showControls
              ? _buildAppBar(theme, safePadding)
              : null,
      drawer: _isFullscreen
          ? null
          : QuranNavigationDrawer(
              onPageSelected: _goToPage,
              currentPage: _currentPage,
            ),
      body: Stack(
        children: [
          GestureDetector(
            onTap: _toggleControls,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isPortrait = constraints.maxWidth <= constraints.maxHeight;
                
                if (_lastIsPortrait != isPortrait) {
                  final initialIndex = isPortrait ? _currentPage - 1 : (_currentPage - 1) ~/ 2;
                  _pageController?.dispose();
                  _pageController = PageController(initialPage: initialIndex);
                  _lastIsPortrait = isPortrait;
                }

                final itemCount = isPortrait ? _totalPages : (_totalPages / 2).ceil();

                return PageView.builder(
                  key: ValueKey('page_view_$isPortrait'),
                  controller: _pageController,
                  reverse: true, // RTL order
                  itemCount: itemCount,
                  onPageChanged: (index) {
                    final newPage = isPortrait ? index + 1 : (index * 2) + 1;
                    if (_currentPage != newPage) {
                      setState(() => _currentPage = newPage);
                      widget.prefsService.saveLastPage(newPage);
                    }
                  },
                  itemBuilder: (context, index) {
                    if (isPortrait) {
                      // Portrait: Single page
                      return ZoomablePage(
                        child: Center(
                          child: _buildImagePage(index + 1, theme),
                        ),
                      );
                    } else {
                      // Landscape: Double page (Mushaf spread)
                      final rightPage = (index * 2) + 1;
                      final leftPage = rightPage + 1;
                      
                      return ZoomablePage(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Left Page (higher number)
                            if (leftPage <= _totalPages)
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: _buildImagePage(leftPage, theme),
                                  ),
                                ),
                              )
                            else
                              const Expanded(child: SizedBox()),
                              
                            // Right Page (lower number)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: _buildImagePage(rightPage, theme),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ),

          // Bottom bar with iOS safe area
          if (_showControls || _isFullscreen)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _fadeController,
                child: _buildBottomBar(theme, safePadding),
              ),
            ),

          // Fullscreen floating menu button with safe area
          if (_isFullscreen && _showControls)
            Positioned(
              top: safePadding.top + 8,
              right: 8,
              child: FadeTransition(
                opacity: _fadeController,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildFloatingButton(
                      icon: Icons.fullscreen_exit,
                      onTap: _toggleFullscreen,
                      theme: theme,
                    ),
                    const SizedBox(width: 8),
                    _buildFloatingButton(
                      icon: Icons.search,
                      onTap: _showGoToPageDialog,
                      theme: theme,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme, EdgeInsets safePadding) {
    return AppBar(
      title: Column(
        children: [
          const Text(
            'القرآن الكريم',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'سورة ${_getCurrentSurahName()}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: theme.appBarTheme.foregroundColor?.withAlpha(180),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.find_in_page_outlined),
          tooltip: 'انتقل إلى صفحة',
          onPressed: _showGoToPageDialog,
        ),
        IconButton(
          icon: Icon(
            _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
          ),
          tooltip: _isFullscreen ? 'إلغاء الشاشة الكاملة' : 'شاشة كاملة',
          onPressed: _toggleFullscreen,
        ),
        IconButton(
          icon: Icon(
            widget.isDarkMode ? Icons.light_mode : Icons.dark_mode,
          ),
          tooltip: widget.isDarkMode ? 'الوضع الفاتح' : 'الوضع الداكن',
          onPressed: widget.onToggleTheme,
        ),
      ],
    );
  }

  Widget _buildBottomBar(ThemeData theme, EdgeInsets safePadding) {
    final isDark = widget.isDarkMode;
    final bottomPadding = safePadding.bottom > 0 ? safePadding.bottom : 8.0;

    return Container(
      padding: EdgeInsets.only(
        bottom: bottomPadding,
        top: 12,
        left: 20,
        right: 20,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            (isDark ? Colors.black : Colors.white).withAlpha(230),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              activeTrackColor: theme.colorScheme.primary,
              inactiveTrackColor: theme.colorScheme.primary.withAlpha(50),
              thumbColor: theme.colorScheme.primary,
              overlayColor: theme.colorScheme.primary.withAlpha(40),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 22),
            ),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Slider(
                value: _currentPage.toDouble().clamp(1, _totalPages.toDouble()),
                min: 1,
                max: _totalPages.toDouble(),
                onChanged: (val) {
                  _goToPage(val.round());
                },
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$_totalPages',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withAlpha(150),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: theme.colorScheme.primary.withAlpha(25),
                  border: Border.all(
                    color: theme.colorScheme.primary.withAlpha(60),
                  ),
                ),
                child: Text(
                  'صفحة $_currentPage',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const Text(
                '1',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingButton({
    required IconData icon,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return Material(
      color: theme.colorScheme.surface.withAlpha(220),
      borderRadius: BorderRadius.circular(12),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, size: 24, color: theme.colorScheme.primary),
        ),
      ),
    );
  }
}
