import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, required this.languageCode});

  final String languageCode;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next(int total) {
    if (_currentPage < total - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.ofCode(widget.languageCode);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final pages = [
      _OnboardingSlide(
        icon: Icons.auto_awesome_rounded,
        iconColor: isDark ? const Color(0xFF9FD9CB) : const Color(0xFF0F5B52),
        bgColor: isDark ? const Color(0xFF18322D) : const Color(0xFFDCEDE7),
        title: strings.onboardingTitle1,
        body: strings.onboardingBody1,
      ),
      _OnboardingSlide(
        icon: Icons.workspaces_outlined,
        iconColor: isDark ? const Color(0xFFB39DDB) : const Color(0xFF4527A0),
        bgColor: isDark ? const Color(0xFF221B38) : const Color(0xFFEDE7F6),
        title: strings.onboardingTitle2,
        body: strings.onboardingBody2,
      ),
      _OnboardingSlide(
        icon: Icons.folder_open_rounded,
        iconColor: isDark ? const Color(0xFF80DEEA) : const Color(0xFF00695C),
        bgColor: isDark ? const Color(0xFF0D2626) : const Color(0xFFE0F2F1),
        title: strings.onboardingTitle3,
        body: strings.onboardingBody3,
      ),
      _OnboardingSlide(
        icon: Icons.rocket_launch_outlined,
        iconColor: isDark ? const Color(0xFFFFCC80) : const Color(0xFFE65100),
        bgColor: isDark ? const Color(0xFF2A1F0D) : const Color(0xFFFFF3E0),
        title: strings.onboardingTitle4,
        body: strings.onboardingBody4,
      ),
    ];

    final isLast = _currentPage == pages.length - 1;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(strings.onboardingSkip),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: pages.length,
                onPageChanged: (index) =>
                    setState(() => _currentPage = index),
                itemBuilder: (context, index) => pages[index],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                pages.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? (isDark
                              ? const Color(0xFF9FD9CB)
                              : const Color(0xFF0F5B52))
                        : (isDark
                              ? const Color(0xFF3A4A47)
                              : const Color(0xFFBDBDBD)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => _next(pages.length),
                  child: Text(
                    isLast ? strings.start : strings.onboardingNext,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _OnboardingSlide extends StatelessWidget {
  const _OnboardingSlide({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(icon, size: 48, color: iconColor),
          ),
          const SizedBox(height: 32),
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            body,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
