import 'package:cricstatz/config/palette.dart';
import 'package:cricstatz/config/routes.dart';
import 'package:cricstatz/models/match.dart';
import 'package:cricstatz/services/match_service.dart';
import 'package:cricstatz/widgets/skeleton_loaders.dart';
import 'package:flutter/material.dart';
import 'dart:ui' show ImageFilter;

class MatchInfoScreen extends StatefulWidget {
  final String? matchId;
  const MatchInfoScreen({super.key, this.matchId});

  @override
  State<MatchInfoScreen> createState() => _MatchInfoScreenState();
}

class _MatchInfoScreenState extends State<MatchInfoScreen> {
  Match? _match;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (widget.matchId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      final match = await MatchService.getMatchDetails(widget.matchId!);
      if (mounted) {
        setState(() {
          _match = match;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  static const _stadiumImg =
      'https://www.figma.com/api/mcp/asset/33423223-3ca2-4619-8967-429d142aa978';
  static const _mapImg =
      'https://www.figma.com/api/mcp/asset/1184f189-9712-439b-aa09-96ecbd7b36be';
  static const _indFlag =
      'https://www.figma.com/api/mcp/asset/7820bf67-988e-47a5-bd50-3578c658f8e3';
  static const _ausFlag =
      'https://www.figma.com/api/mcp/asset/f4b32dcb-4957-466f-b827-2688b91170b1';

  static Color get _cardBg => AppPalette.cardPrimary;
  static Color get _cardBorder => AppPalette.cardStroke;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: AppPalette.surfaceGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              children: [
                _buildHeader(context),
                _buildTabs(context, widget.matchId),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _isLoading 
                      ? const MatchInfoLoader()
                      : Column(
                          children: [
                            _buildMatchSummaryCard(context),
                            const SizedBox(height: 16),
                            _buildVenueDetailsCard(context),
                            const SizedBox(height: 16),
                            _buildWeatherPitchRow(context),
                            const SizedBox(height: 16),
                            _buildHeadToHeadCard(context),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          height: 72,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          decoration: BoxDecoration(
            color: AppPalette.bgPrimary,
            border: Border(bottom: BorderSide(color: AppPalette.cardStroke)),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.home,
                  (route) => false,
                ),
                icon: Icon(Icons.arrow_back_ios_new,
                    color: AppPalette.textPrimary, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${_match?.teamAId ?? "Loading..."} vs ${_match?.teamBId ?? ""}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppPalette.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _match?.matchFormat ?? 'Match Info',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppPalette.textSubtle,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: Icon(Icons.share_outlined,
                    color: AppPalette.textPrimary, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabs(BuildContext context, String? matchId) {
    const tabs = ['INFO', 'LIVE', 'SCORECARD', 'PLAYERS'];
    const selectedIndex = 0;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          height: 51,
          decoration: BoxDecoration(
            color: AppPalette.bgPrimary,
            border: Border(bottom: BorderSide(color: AppPalette.cardStroke)),
          ),
          child: Row(
            children: List.generate(tabs.length, (i) {
              final isSelected = i == selectedIndex;
              return Expanded(
                child: InkWell(
                  onTap: () {
                    if (i == selectedIndex) return;
                    if (i == 1) {
                      Navigator.pushNamed(context, AppRoutes.live, arguments: matchId);
                    } else if (i == 2) {
                      Navigator.pushNamed(context, AppRoutes.scoreboard, arguments: matchId);
                    } else if (i == 3) {
                      Navigator.pushNamed(context, AppRoutes.players, arguments: matchId);
                    }
                  },
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isSelected
                              ? AppPalette.accent
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 15),
                    child: Text(
                      tabs[i],
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: isSelected
                                ? AppPalette.accent
                                : AppPalette.textMuted,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            letterSpacing: 0.6,
                          ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildMatchSummaryCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.network(
              _stadiumImg,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: _cardBorder,
                alignment: Alignment.center,
                child: Icon(Icons.image_not_supported_outlined,
                    color: AppPalette.textMuted),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppPalette.live,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'MATCH RESULT',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: AppPalette.textMuted,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Text(
                  'Australia won by 6 wickets',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppPalette.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                      ),
                ),
                SizedBox(height: 10),
                Text(
                  'Australia chased down 241 runs in 43 overs.\n'
                  'Travis Head scored a brilliant 137 off 120 balls\n'
                  'to secure the title for Australia.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppPalette.textMuted,
                        height: 1.5,
                      ),
                ),
                SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: FilledButton(
                    onPressed: () {},
                    style: FilledButton.styleFrom(
                      backgroundColor: AppPalette.bgSecondary,
                      foregroundColor: AppPalette.textPrimary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text(
                      'View Full Scorecard',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVenueDetailsCard(BuildContext context) {
    Widget row(String label, String value, {bool last = false}) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: last ? Colors.transparent : _cardBorder,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppPalette.textMuted,
                    ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppPalette.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.stadium_outlined,
                  size: 20, color: AppPalette.textPrimary),
              SizedBox(width: 8),
              Text(
                'Venue Details',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppPalette.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          row('Venue', _match?.venue ?? 'TBD'),
          row('City', _match?.venueCity ?? 'TBD'),
          row('Capacity', _match?.venueCapacity ?? 'TBD'),
          row('Ends', _match?.venueEnds ?? 'TBD', last: true),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 128,
              width: double.infinity,
              child: Image.network(
                _mapImg,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: _cardBorder,
                  alignment: Alignment.center,
                  child: Icon(Icons.map_outlined,
                      color: AppPalette.textMuted),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherPitchRow(BuildContext context) {
    Widget card({
      required Widget leadingIcon,
      required String title,
      required Widget body,
    }) {
      return Expanded(
        child: Container(
          height: 157,
          padding: const EdgeInsets.all(21),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _cardBorder),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  leadingIcon,
                  SizedBox(width: 8),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppPalette.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(child: body),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        card(
          leadingIcon: Icon(Icons.cloud_outlined,
              color: AppPalette.textPrimary, size: 20),
          title: 'Weather',
          body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _match?.weatherTemp ?? '--°C',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: AppPalette.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 30,
                    ),
              ),
              SizedBox(height: 4),
              Text(
                _match?.weatherDesc ?? 'N/A',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppPalette.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.water_drop_outlined,
                      size: 14, color: AppPalette.textMuted),
                  SizedBox(width: 4),
                  Text(
                    'Humidity: ${_match?.humidity ?? "--%"}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppPalette.textMuted,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(width: 16),
        card(
          leadingIcon: Icon(Icons.sports_cricket_outlined,
              color: AppPalette.textPrimary, size: 20),
          title: 'Pitch',
          body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _match?.pitchType ?? 'Balanced',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppPalette.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              SizedBox(height: 4),
              Text(
                _match?.pitchDesc ?? 'Spin friendly',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppPalette.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: SizedBox(
                  height: 6,
                  width: double.infinity,
                  child: Row(
                    children: [
                      Expanded(
                        flex: _match?.paceRatio ?? 50,
                        child: Container(color: AppPalette.progress),
                      ),
                      Expanded(
                        flex: _match?.spinRatio ?? 50,
                        child: Container(color: AppPalette.live),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pace ${_match?.paceRatio ?? 50}%',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppPalette.textMuted,
                        ),
                  ),
                  Text(
                    'Spin ${_match?.spinRatio ?? 50}%',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppPalette.textMuted,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeadToHeadCard(BuildContext context) {
    Widget flagCircle(String url) {
      return Container(
        width: 64,
        height: 64,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(color: AppPalette.cardStroke, width: 2),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(color: AppPalette.cardStroke, width: 2),
          ),
          padding: EdgeInsets.all(10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(Icons.flag_outlined,
                  color: AppPalette.textMuted, size: 20),
            ),
          ),
        ),
      );
    }

    Widget stat(String label, String value) {
      return Column(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppPalette.textSubtle,
                ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppPalette.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.compare_arrows_outlined,
                      size: 20, color: AppPalette.textPrimary),
                  SizedBox(width: 8),
                  Text(
                    'Head-to-Head',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppPalette.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _cardBorder,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'LAST 10 MATCHES',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppPalette.textSubtle,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    flagCircle(_indFlag),
                    SizedBox(height: 8),
                    Text(
                      'IND',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppPalette.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_match?.headToHeadA ?? 0}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppPalette.accent,
                            fontWeight: FontWeight.w700,
                            fontSize: 24,
                          ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Container(width: 1, height: 40, color: _cardBorder),
                  SizedBox(height: 8),
                  Text(
                    'VS',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppPalette.textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Container(width: 1, height: 40, color: _cardBorder),
                ],
              ),
              Expanded(
                child: Column(
                  children: [
                    flagCircle(_ausFlag),
                    SizedBox(height: 8),
                    Text(
                      'AUS',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppPalette.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_match?.headToHeadB ?? 0}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppPalette.accent,
                            fontWeight: FontWeight.w700,
                            fontSize: 24,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Container(height: 1, color: _cardBorder),
          SizedBox(height: 18),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'TOSS HISTORY AT VENUE',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppPalette.textMuted,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppPalette.cardStroke,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                stat('Opt to Bat', '40%'),
                stat('Win Batting 1st', '35%'),
                stat('Avg 1st Inn Score', '247'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
