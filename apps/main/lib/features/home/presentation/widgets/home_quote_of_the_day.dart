import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:core/core.dart';

import 'package:app_main/features/quotes/domain/entities/quote_entity.dart';
import 'package:app_main/features/quotes/presentation/quotes_notifier.dart';

class HomeQuoteOfTheDay extends ConsumerStatefulWidget {
  const HomeQuoteOfTheDay({super.key});

  @override
  ConsumerState<HomeQuoteOfTheDay> createState() => _HomeQuoteOfTheDayState();
}

class _HomeQuoteOfTheDayState extends ConsumerState<HomeQuoteOfTheDay> {
  PageController? _pageController;

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  /// Deterministically selects a single active quote for the entire day.
  QuoteEntity? _getQuoteOfTheDay(List<QuoteEntity> quotes) {
    final activeQuotes = quotes.where((q) => q.isActive).toList();
    if (activeQuotes.isEmpty) return null;

    final now = DateTime.now();
    // Unique integer hash representing today's date (YYYYMMDD)
    final dayHash = now.year * 10000 + now.month * 100 + now.day;
    final index = dayHash % activeQuotes.length;
    return activeQuotes[index];
  }

  List<QuoteEntity> _getCarouselQuotes(List<QuoteEntity> quotes) {
    final activeQuotes = quotes.where((q) => q.isActive).toList();
    if (activeQuotes.isEmpty) return [];

    final qotd = _getQuoteOfTheDay(quotes);
    if (qotd == null) return [];

    final result = <QuoteEntity>[qotd];

    // Add other active quotes, excluding QOTD
    final others = activeQuotes.where((q) => q.id != qotd.id).toList();
    result.addAll(others);

    return result;
  }

  void _copyToClipboard(
      BuildContext context, QuoteEntity quote, AppLocalizations l10n) {
    final textToCopy =
        '"${quote.text}"\n\n— ${quote.author}${quote.source != null && quote.source!.isNotEmpty ? " (${quote.source})" : ""}';
    Clipboard.setData(ClipboardData(text: textToCopy)).then((_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.quoteOfTheDayCopySuccess,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green.shade600,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final quotesAsync = ref.watch(quotesProvider);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return quotesAsync.when(
      loading: () => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: _buildShimmerLoading(theme),
      ),
      error: (err, _) =>
          const SizedBox.shrink(), // Silently hide or show minimal on error
      data: (quotes) {
        final carouselQuotes = _getCarouselQuotes(quotes);

        if (carouselQuotes.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: _buildEmptyState(context, l10n, theme),
          );
        }

        return _buildCarousel(context, carouselQuotes, l10n, theme, isDark);
      },
    );
  }

  Widget _buildCarousel(
    BuildContext context,
    List<QuoteEntity> quotes,
    AppLocalizations l10n,
    ThemeData theme,
    bool isDark,
  ) {
    final N = quotes.length;
    if (_pageController == null) {
      final initialPage = N > 1 ? (5000 ~/ N) * N : 0;
      _pageController = PageController(initialPage: initialPage);
    }

    return SizedBox(
      height: 200,
      child: PageView.builder(
        controller: _pageController,
        itemCount: N > 1 ? 10000 : 1,
        itemBuilder: (context, index) {
          final quoteIndex = index % N;
          final quote = quotes[quoteIndex];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: _buildPremiumQuoteCard(
                context, quote, quoteIndex == 0, l10n, theme, isDark),
          );
        },
      ),
    );
  }

  Widget _buildPremiumQuoteCard(
    BuildContext context,
    QuoteEntity quote,
    bool isQotd,
    AppLocalizations l10n,
    ThemeData theme,
    bool isDark,
  ) {
    final colorScheme = theme.colorScheme;

    // Premium gradients:
    // Light mode uses a vibrant indigo/purple gradient
    // Dark mode uses a sleek, rich deep blue/violet gradient
    final gradientColors = isDark
        ? [
            const Color(0xFF1E1E38),
            const Color(0xFF2C1E4A),
          ]
        : [
            colorScheme.primary,
            colorScheme.primary
                .withBlue((colorScheme.primary.blue + 40).clamp(0, 255)),
          ];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : colorScheme.primary)
                .withOpacity(isDark ? 0.4 : 0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Double quotes watermark icon
            Positioned(
              right: -10,
              top: -20,
              child: Icon(
                Icons.format_quote_rounded,
                size: 150,
                color: Colors.white.withOpacity(0.06),
              ),
            ),

            // Content
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => context.push(AppRoutes.quotes),
                splashColor: Colors.white.withOpacity(0.08),
                highlightColor: Colors.white.withOpacity(0.04),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Header Row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.15),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isQotd
                                      ? Icons.auto_awesome_rounded
                                      : Icons.lightbulb_outline_rounded,
                                  color: Colors.amber,
                                  size: 14,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  (isQotd
                                          ? l10n.quoteOfTheDayTitle
                                          : 'Kutipan Pilihan')
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          // Elegant Copy Button
                          Material(
                            color: Colors.white.withOpacity(0.1),
                            shape: const CircleBorder(),
                            child: IconButton(
                              icon: const Icon(
                                Icons.copy_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                              tooltip: l10n.quotesSave,
                              onPressed: () =>
                                  _copyToClipboard(context, quote, l10n),
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(6),
                            ),
                          ),
                        ],
                      ),

                      // Quote content text (Expanded with vertical scrolling)
                      Expanded(
                        child: Center(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                quote.text,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  height: 1.4,
                                  fontStyle: FontStyle.italic,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black26,
                                      offset: Offset(0, 1),
                                      blurRadius: 3,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Author & Source
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Text(
                          '— ${quote.author}${quote.source != null && quote.source!.isNotEmpty ? " (${quote.source})" : ""}',
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
      BuildContext context, AppLocalizations l10n, ThemeData theme) {
    final colorScheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => context.push(AppRoutes.quotes),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.format_quote_rounded,
                    color: colorScheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.quoteOfTheDayTitle,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.quoteOfTheDayEmpty,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerLoading(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    return Container(
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
          ),
        ),
      ),
    );
  }
}
