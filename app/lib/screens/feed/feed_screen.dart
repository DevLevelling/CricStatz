import 'package:cricstatz/config/palette.dart';
import 'package:cricstatz/widgets/app_bottom_nav_bar.dart';
import 'package:flutter/material.dart';

/// Placeholder Feed screen — shows a 'Coming Soon' state.
/// Future: integrate cricket news API.
class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.bgPrimary,
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 0),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppPalette.cardPrimary,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppPalette.cardStroke),
                  ),
                  child: Icon(Icons.newspaper_rounded,
                      size: 40, color: AppPalette.accent),
                ),
                const SizedBox(height: 24),
                Text('Cricket Feed',
                    style: TextStyle(
                        color: AppPalette.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(
                  'Live cricket news and match updates coming soon.',
                  style:
                      TextStyle(color: AppPalette.textMuted, fontSize: 14, height: 1.6),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
