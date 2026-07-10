import 'package:cricstatz/config/palette.dart';
import 'package:cricstatz/providers/auth_provider.dart';
import 'package:cricstatz/providers/theme_provider.dart';
import 'package:cricstatz/services/profile_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

String _formatRole(String role) {
  return role
      .split('-')
      .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.bgPrimary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            children: [
              _Header(),
              const _ProfileBody(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: AppPalette.bgSecondary,
        border: Border(
          bottom: BorderSide(color: AppPalette.cardStroke),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back_ios_new,
                color: AppPalette.textPrimary, size: 20),
          ),
          Expanded(
            child: Text(
              'Player Profile',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppPalette.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const _SunMoonThemeSwitch(),
          SizedBox(width: 4),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.settings_outlined,
              color: AppPalette.textPrimary,
              size: 20,
            ),
            onSelected: (value) async {
              if (value == 'logout') {
                await context.read<AuthProvider>().signOut();
                if (context.mounted) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem<String>(
                value: 'logout',
                child: Text('Logout'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          _ProfileHeaderCard(),
          const SizedBox(height: 16),
          _QuickStatsRow(),
          const SizedBox(height: 16),
          _ProfileTabs(),
          const SizedBox(height: 16),
          _MatchHistoryList(),
        ],
      ),
    );
  }
}

void _showEditProfileSheet(BuildContext context) {
  final auth = context.read<AuthProvider>();
  final profile = auth.profile;
  if (profile == null) return;

  final usernameController = TextEditingController(text: profile.username);
  final displayNameController =
      TextEditingController(text: profile.displayName);
  String selectedRole = profile.role;
  bool isSaving = false;

  const roles = ['batter', 'bowler', 'all-rounder', 'wicket-keeper'];

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppPalette.bgSecondary,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              24,
              24,
              24 + MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit Profile',
                  style: TextStyle(
                    color: AppPalette.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: displayNameController,
                  style: TextStyle(color: AppPalette.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Display Name',
                    labelStyle:
                        TextStyle(color: AppPalette.textMuted),
                    enabledBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: AppPalette.cardStroke),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: AppPalette.accent),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                SizedBox(height: 14),
                TextField(
                  controller: usernameController,
                  style: TextStyle(color: AppPalette.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Username',
                    labelStyle:
                        TextStyle(color: AppPalette.textMuted),
                    prefixText: '@',
                    prefixStyle:
                        TextStyle(color: AppPalette.textMuted),
                    enabledBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: AppPalette.cardStroke),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: AppPalette.accent),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                SizedBox(height: 14),
                Text(
                  'Role',
                  style: TextStyle(
                    color: AppPalette.textMuted,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: roles.map((r) {
                    final selected = r == selectedRole;
                    return ChoiceChip(
                      label: Text(_formatRole(r)),
                      selected: selected,
                      selectedColor: AppPalette.accent,
                      backgroundColor: AppPalette.cardOverlay,
                      labelStyle: TextStyle(
                        color: selected
                            ? AppPalette.bgPrimary
                            : AppPalette.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      onSelected: (_) {
                        setSheetState(() => selectedRole = r);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            final newUsername =
                                usernameController.text.trim();
                            final newDisplay =
                                displayNameController.text.trim();
                            if (newUsername.isEmpty ||
                                newDisplay.isEmpty) return;

                            setSheetState(() => isSaving = true);

                            try {
                              await ProfileService.updateProfile(
                                userId: profile.id,
                                username: newUsername,
                                displayName: newDisplay,
                                role: selectedRole,
                              );
                              await auth.refreshProfile();
                              if (ctx.mounted) Navigator.pop(ctx);
                            } catch (e) {
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                    content:
                                        Text('Failed to update: $e'),
                                  ),
                                );
                              }
                            } finally {
                              if (ctx.mounted) {
                                setSheetState(() => isSaving = false);
                              }
                            }
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppPalette.accent,
                      foregroundColor: AppPalette.bgPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: isSaving
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppPalette.bgPrimary,
                            ),
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

class _ProfileHeaderCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthProvider>().profile;
    final displayName = profile?.displayName ?? 'Player';
    final role = profile?.role ?? 'batter';
    final avatarUrl = profile?.avatarUrl;
    final username = profile?.username ?? '';
    final inviteCode = profile?.inviteCode ?? '';

    return Column(
      children: [
        Container(
          width: 128,
          height: 128,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppPalette.accent.withOpacity(0.2),
              width: 4,
            ),
          ),
          child: ClipOval(
            child: avatarUrl != null && avatarUrl.isNotEmpty
                ? Image.network(
                    avatarUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppPalette.cardPrimary,
                      alignment: Alignment.center,
                      child: Text(
                        displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: AppPalette.accent,
                          fontSize: 48,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                : Container(
                    color: AppPalette.cardPrimary,
                    alignment: Alignment.center,
                    child: Text(
                      displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: AppPalette.accent,
                        fontSize: 48,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
          ),
        ),
        SizedBox(height: 12),
        Text(
          displayName,
          style: TextStyle(
            color: AppPalette.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 4),
        Text(
          '@$username  •  ${_formatRole(role)}',
          style: TextStyle(
            color: AppPalette.textMuted,
            fontSize: 14,
          ),
        ),
        if (inviteCode.isNotEmpty) ...[
          SizedBox(height: 6),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppPalette.cardPrimary,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppPalette.cardStroke),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.tag, size: 14, color: AppPalette.accent),
                SizedBox(width: 4),
                Text(
                  inviteCode,
                  style: TextStyle(
                    color: AppPalette.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ],
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _showEditProfileSheet(context),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppPalette.cardStroke),
                  foregroundColor: AppPalette.textPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Edit Profile',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () {},
                style: FilledButton.styleFrom(
                  backgroundColor: AppPalette.bgSecondary,
                  foregroundColor: AppPalette.textPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Follow',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickStatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Widget card(String value, String label, {Color? valueColor}) {
      return Expanded(
        child: Container(
          padding: EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: AppPalette.cardPrimary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppPalette.cardStroke),
          ),
          child: Column(
            children: [
              Text(
                value,
                style: TextStyle(
                  color: valueColor ?? AppPalette.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 4),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  color: AppPalette.textMuted,
                  fontSize: 11,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        card('24', 'Matches'),
        SizedBox(width: 12),
        card('1250', 'Runs', valueColor: AppPalette.accent),
        const SizedBox(width: 12),
        card('85', 'Wickets'),
      ],
    );
  }
}

class _ProfileTabs extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const tabs = ['Overview', 'Matches', 'Stats'];
    const selectedIndex = 1;
    return Container(
      margin: EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppPalette.cardStroke)),
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final selected = i == selectedIndex;
          return Expanded(
            child: Container(
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: selected ? AppPalette.accent : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                tabs[i],
                style: TextStyle(
                  color: selected ? AppPalette.accent : AppPalette.textMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _MatchHistoryList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _MatchCard(
          title: 'Final • Oct 24, 2023',
          opponent: 'vs Scorchers XI',
          resultLabel: 'WON',
          resultColor: AppPalette.success,
          batting: '45 (30)',
          bowling: '2/24 (4)',
        ),
        SizedBox(height: 12),
        _MatchCard(
          title: 'Semi-Final • Oct 20, 2023',
          opponent: 'vs Thunder Bolts',
          resultLabel: 'LOST',
          resultColor: AppPalette.live,
          batting: '12 (15)',
          bowling: '0/35 (3)',
        ),
        SizedBox(height: 12),
        _MatchCard(
          title: 'League • Oct 15, 2023',
          opponent: 'vs Rapid Strikers',
          resultLabel: 'WON',
          resultColor: AppPalette.success,
          batting: '82* (54)',
          bowling: '1/18 (2)',
        ),
      ],
    );
  }
}

class _MatchCard extends StatelessWidget {
  final String title;
  final String opponent;
  final String resultLabel;
  final Color resultColor;
  final String batting;
  final String bowling;

  const _MatchCard({
    required this.title,
    required this.opponent,
    required this.resultLabel,
    required this.resultColor,
    required this.batting,
    required this.bowling,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppPalette.cardPrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppPalette.cardStroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppPalette.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppPalette.cardStroke.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.person,
                            size: 16, color: AppPalette.textMuted),
                      ),
                      SizedBox(width: 8),
                      Text(
                        opponent,
                        style: TextStyle(
                          color: AppPalette.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: resultColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  resultLabel.toUpperCase(),
                  style: TextStyle(
                    color: resultColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Divider(color: AppPalette.cardStroke),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BATTING',
                      style: TextStyle(
                        color: AppPalette.textMuted,
                        fontSize: 10,
                        letterSpacing: 0.6,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      batting,
                      style: TextStyle(
                        color: AppPalette.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BOWLING',
                      style: TextStyle(
                        color: AppPalette.textMuted,
                        fontSize: 10,
                        letterSpacing: 0.6,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      bowling,
                      style: TextStyle(
                        color: AppPalette.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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

class _SunMoonThemeSwitch extends StatelessWidget {
  const _SunMoonThemeSwitch();

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.currentTheme.isDark;

    return GestureDetector(
      onTap: () => themeProvider.toggleDarkLight(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOut,
        width: 56,
        height: 32,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark ? AppPalette.cardPrimary : AppPalette.bgSecondary,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 380),
              curve: Curves.easeInOut,
              left: isDark ? 24 : 0,
              top: 0,
              child: isDark
                  ? Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppPalette.cardPrimary,
                      ),
                      child: const CustomPaint(
                        painter: _MoonPainter(),
                      ),
                    )
                  : Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.bottomLeft,
                          end: Alignment.topRight,
                          colors: [
                            Color(0xFFFF0080),
                            Color(0xFFFF8C00),
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
}

class _MoonPainter extends CustomPainter {
  const _MoonPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final outerCircle = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));

    final cutoutCircle = Path()
      ..addOval(Rect.fromCircle(
        center: Offset(center.dx - radius * 0.35, center.dy - radius * 0.22),
        radius: radius * 0.88,
      ));

    final crescentPath = Path.combine(
      PathOperation.difference,
      outerCircle,
      cutoutCircle,
    );

    final shadowPaint = Paint()
      ..color = const Color(0xFF8983F7)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawPath(crescentPath, shadowPaint);

    final moonPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [Color(0xFFA3DAFB), Color(0xFF8983F7)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(crescentPath, moonPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


