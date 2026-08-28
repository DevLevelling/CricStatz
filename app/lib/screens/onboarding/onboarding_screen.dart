import 'package:cricstatz/config/palette.dart';
import 'package:cricstatz/services/local_storage_service.dart';
import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  /// Called when the user completes or skips onboarding.
  /// Optional — when used via named route this is left null and we just pop.
  final VoidCallback? onCompleted;

  const OnboardingScreen({super.key, this.onCompleted});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<_OnboardingData> _pages = [
    _OnboardingData(
      icon: Icons.sports_cricket_rounded,
      title: 'Score Matches Live',
      description:
          'Record every ball with our smart scoring engine. Track runs, wickets, wides, no-balls and more — ball by ball.',
      gradientA: Color(0xFF00C2FF),
      gradientB: Color(0xFF0066FF),
    ),
    _OnboardingData(
      icon: Icons.bar_chart_rounded,
      title: 'Track Your Career',
      description:
          'View batting averages, strike rates, bowling economy and wickets across all matches. Your stats, your story.',
      gradientA: Color(0xFF4ADE80),
      gradientB: Color(0xFF059669),
    ),
    _OnboardingData(
      icon: Icons.group_rounded,
      title: 'Manage Your Team',
      description:
          'Create teams, add squad members, and organise matches with your friends and club. Cricket made simple.',
      gradientA: Color(0xFFF59E0B),
      gradientB: Color(0xFFEF4444),
    ),
  ];

  Future<void> _finish() async {
    await LocalStorageService.setBool('onboarding_done', true);
    if (widget.onCompleted != null) {
      widget.onCompleted!();
    } else if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _finish,
                child: Text('Skip',
                    style: TextStyle(color: AppPalette.textMuted, fontSize: 15)),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, index) =>
                    _OnboardingPage(data: _pages[index]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Progress dots
                  Row(
                    children: List.generate(
                      _pages.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.only(right: 6),
                        width: _currentPage == i ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == i
                              ? AppPalette.accent
                              : AppPalette.cardStroke,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  // Next / Get Started button
                  FilledButton(
                    onPressed: () {
                      if (_currentPage < _pages.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        _finish();
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppPalette.accent,
                      foregroundColor: AppPalette.bgPrimary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(32)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 14),
                    ),
                    child: Text(
                      _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingData {
  final IconData icon;
  final String title, description;
  final Color gradientA, gradientB;
  const _OnboardingData({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradientA,
    required this.gradientB,
  });
}

class _OnboardingPage extends StatelessWidget {
  final _OnboardingData data;
  const _OnboardingPage({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [data.gradientA, data.gradientB],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Icon(data.icon, size: 72, color: Colors.white),
          ),
          const SizedBox(height: 48),
          Text(
            data.title,
            style: TextStyle(
              color: AppPalette.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            data.description,
            style: TextStyle(
              color: AppPalette.textMuted,
              fontSize: 15,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
