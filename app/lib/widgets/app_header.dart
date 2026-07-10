import 'package:cricstatz/config/assets.dart';
import 'package:flutter/material.dart';

/// Shared app header with centered logo. [trailing] customizes the right-side content.
/// Uses fixed dimensions so the navbar stays the same size during page transitions.
class AppHeader extends StatelessWidget {
  const AppHeader({super.key, this.trailing});

  /// Right-side widget. Defaults to notification icon; use for calendar+filter etc.
  final Widget? trailing;

  /// Fixed height of the header row (logo + padding). Keeps navbar stable across transitions.
  static const double height = 55;

  /// Fixed logo size so it doesn't scale or jump between pages.
  static const double logoHeight = 35;
  static const double logoWidth = 142;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            const SizedBox(width: 40),
            Expanded(
              child: Center(
                child: SizedBox(
                  width: logoWidth,
                  height: logoHeight,
                  child: Image.asset(
                    AppAssets.logo,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
