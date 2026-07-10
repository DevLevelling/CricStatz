import 'package:cricstatz/config/palette.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SkeletonLoader extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const SkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = AppPalette.cardPrimary;
    final highlightColor = AppPalette.cardStroke;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class ScoreBannerLoader extends StatelessWidget {
  const ScoreBannerLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppPalette.cardPrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppPalette.cardStroke),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SkeletonLoader(width: 80, height: 12),
                  SizedBox(height: 8),
                  SkeletonLoader(width: 120, height: 32),
                  SizedBox(height: 8),
                  SkeletonLoader(width: 100, height: 14),
                ],
              ),
              const SkeletonLoader(width: 50, height: 24, borderRadius: BorderRadius.all(Radius.circular(50))),
            ],
          ),
          const SizedBox(height: 24),
          Divider(color: AppPalette.cardStroke),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SkeletonLoader(width: 100, height: 10),
                    SizedBox(height: 8),
                    SkeletonLoader(width: 80, height: 14),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: const [
                    SkeletonLoader(width: 100, height: 10),
                    SizedBox(height: 8),
                    SkeletonLoader(width: 40, height: 14),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MatchInfoLoader extends StatelessWidget {
  const MatchInfoLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppPalette.cardPrimary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const SkeletonLoader(width: double.infinity, height: 200),
        ),
        const SizedBox(height: 16),
        const SkeletonLoader(width: double.infinity, height: 150),
        const SizedBox(height: 16),
        Row(
          children: const [
            Expanded(child: SkeletonLoader(width: double.infinity, height: 150)),
            SizedBox(width: 16),
            Expanded(child: SkeletonLoader(width: double.infinity, height: 150)),
          ],
        ),
      ],
    );
  }
}

class PlayersListLoader extends StatelessWidget {
  const PlayersListLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        6,
        (index) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              const SkeletonLoader(width: 48, height: 48, borderRadius: BorderRadius.all(Radius.circular(24))),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SkeletonLoader(width: 120, height: 16),
                  SizedBox(height: 4),
                  SkeletonLoader(width: 80, height: 12),
                ],
              ),
              const Spacer(),
              const SkeletonLoader(width: 50, height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeLiveMatchLoader extends StatelessWidget {
  const HomeLiveMatchLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.cardPrimary,
        border: Border.all(color: AppPalette.cardStroke, width: 1.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              SkeletonLoader(width: 100, height: 28),
              SkeletonLoader(width: 120, height: 20),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              SkeletonLoader(width: 58, height: 58, borderRadius: BorderRadius.all(Radius.circular(29))),
              SkeletonLoader(width: 120, height: 44),
              SkeletonLoader(width: 58, height: 58, borderRadius: BorderRadius.all(Radius.circular(29))),
            ],
          ),
          const SizedBox(height: 16),
          const SkeletonLoader(width: double.infinity, height: 38),
          const SizedBox(height: 16),
          const SkeletonLoader(width: double.infinity, height: 46),
        ],
      ),
    );
  }
}
