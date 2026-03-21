import 'package:cricstatz/config/palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'squads.dart';
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// DESIGN TOKENS
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _Tokens {
  static const Color surface1 = Color(0xFF0B1829);
  static const Color surface2 = Color(0xFF0F2040);
  static const Color surface3 = Color(0xFF162A4D);
  static const Color border = Color(0xFF1E3055);
  static const Color teamA = Color(0xFF38BDF8);
  static const Color teamB = Color(0xFFF87171);
  static const Color error = Color(0xFFFF6B6B);
  static const Color muted = Color(0xFF64748B);

  static const TextStyle labelStyle = TextStyle(
    color: Color(0xFF94A3B8),
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
  );

  static const TextStyle fieldStyle = TextStyle(
    color: AppPalette.textPrimary,
    fontSize: 15,
    fontWeight: FontWeight.w500,
  );
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// SCREEN
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class CreateMatchScreen extends StatefulWidget {
  const CreateMatchScreen({super.key});

  @override
  State<CreateMatchScreen> createState() => _CreateMatchScreenState();
}

class _CreateMatchScreenState extends State<CreateMatchScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _titleCtrl = TextEditingController();
  final _teamACtrl = TextEditingController();
  final _teamBCtrl = TextEditingController();
  final _venueCtrl = TextEditingController();
  final _oversCtrl = TextEditingController();
  final _ballsCtrl = TextEditingController(text: '6');

  // State
  String _format = 'T20';
  String _ballType = 'Red Leather';
  String _pitchType = 'Grass';
  DateTime? _date;
  TimeOfDay? _time;
  bool _submitted = false;

  // Animation
  late final AnimationController _pulse;
  late final Animation<double> _pulseAnim;

  static const _formats = [
    ('T20', Icons.flash_on_rounded, '20 overs'),
    ('ODI', Icons.sports_cricket_rounded, '50 overs'),
    ('TEST', Icons.hourglass_bottom_rounded, '5 days'),
    ('CUSTOM', Icons.tune_rounded, 'Custom'),
  ];

  static const _ballTypes = [
    'Red Leather',
    'White Leather',
    'Tennis',
    'Tape Ball',
  ];

  static const _pitchTypes = ['Grass', 'Dry / Dusty', 'Green Top', 'Flat'];

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    for (final c in [_titleCtrl, _teamACtrl, _teamBCtrl, _venueCtrl, _oversCtrl, _ballsCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  // â”€â”€ Pickers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 730)),
      builder: _pickerTheme,
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
      builder: _pickerTheme,
    );
    if (picked != null) setState(() => _time = picked);
  }

  Widget _pickerTheme(BuildContext ctx, Widget? child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppPalette.accent,
            onPrimary: Color(0xFF0B1829),
            surface: Color(0xFF0F2040),
            onSurface: AppPalette.textPrimary,
          ),
          dialogTheme: const DialogThemeData(backgroundColor: Color(0xFF0B1829)),
        ),
        child: child!,
      );

  // â”€â”€ Validation â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  void _onNext() {
    setState(() => _submitted = true);
    HapticFeedback.lightImpact();
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF1A0A0A),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: const Row(
            children: [
              Icon(Icons.error_outline_rounded, color: _Tokens.error, size: 18),
              SizedBox(width: 10),
              Text(
                'Please fill in all required fields.',
                style: TextStyle(color: AppPalette.textPrimary),
              ),
            ],
          ),
        ),
      );
      return;
    }
    // Combine date and time into a single DateTime
    final matchDateTime = _time != null && _date != null
        ? _date!.add(Duration(hours: _time!.hour, minutes: _time!.minute))
        : _date;

    // Navigate to squad selection
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SquadsScreen(
          teamAName: _teamACtrl.text.trim().isEmpty ? 'Team A' : _teamACtrl.text.trim(),
          teamBName: _teamBCtrl.text.trim().isEmpty ? 'Team B' : _teamBCtrl.text.trim(),
          venue: _venueCtrl.text.trim().isEmpty ? null : _venueCtrl.text.trim(),
          format: _format,
          date: matchDateTime,
          overs: int.tryParse(_oversCtrl.text) ?? 20,
        ),
      ),
    );
  }

  // â”€â”€ String helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  // â”€â”€ Build â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Tokens.surface1,
      body: SafeArea(
        child: Column(
          children: [
            RepaintBoundary(child: _Header(pulseAnim: _pulseAnim)),
            const _StepBar(),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── 1. Match Info ──────────────────────────
                      const _SectionHeader(title: 'MATCH INFO', icon: Icons.sports_cricket_rounded),
                      _ValidatedField(
                        controller: _titleCtrl,
                        label: 'MATCH TITLE',
                        hint: 'e.g. Weekend Warriors Cup',
                        icon: Icons.emoji_events_outlined,
                        maxLength: 60,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Match title is required' : null,
                      ),
                      const SizedBox(height: 20),
                      _FormatPicker(
                        formats: _formats,
                        selected: _format,
                        onSelect: (f) => setState(() => _format = f),
                      ),
                      if (_format == 'CUSTOM') ...[
                        const SizedBox(height: 16),
                        _CustomOversRow(
                          oversCtrl: _oversCtrl,
                          ballsCtrl: _ballsCtrl,
                          submitted: _submitted,
                        ),
                      ],
                      const SizedBox(height: 24),

                      // ── 2. Teams ───────────────────────────────
                      const _SectionHeader(title: 'TEAMS', icon: Icons.groups_2_rounded),
                      _ValidatedField(
                        controller: _teamACtrl,
                        label: 'HOME TEAM',
                        hint: 'Team A name',
                        icon: Icons.shield_outlined,
                        accentColor: _Tokens.teamA,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Home team name is required' : null,
                      ),
                      const SizedBox(height: 16),
                      const _VsDivider(),
                      const SizedBox(height: 16),
                      _ValidatedField(
                        controller: _teamBCtrl,
                        label: 'AWAY TEAM',
                        hint: 'Team B name',
                        icon: Icons.shield_outlined,
                        accentColor: _Tokens.teamB,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Away team name is required' : null,
                      ),
                      const SizedBox(height: 24),

                      // ── 3. Venue & Schedule ────────────────────
                      const _SectionHeader(title: 'VENUE & SCHEDULE', icon: Icons.stadium_outlined),
                      _ValidatedField(
                        controller: _venueCtrl,
                        label: 'VENUE',
                        hint: 'Stadium or City',
                        icon: Icons.location_on_outlined,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Venue is required' : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _TapField(
                              label: 'DATE',
                              icon: Icons.calendar_month_rounded,
                              value: _date != null ? _formatDate(_date!) : null,
                              hint: 'Select date',
                              hasError: _submitted && _date == null,
                              onTap: _pickDate,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _TapField(
                              label: 'TIME',
                              icon: Icons.schedule_rounded,
                              value: _time?.format(context),
                              hint: 'Select time',
                              hasError: _submitted && _time == null,
                              onTap: _pickTime,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ── 4. Match Settings ──────────────────────
                      const _SectionHeader(title: 'MATCH SETTINGS', icon: Icons.tune_rounded),
                      _DropdownField(
                        label: 'BALL TYPE',
                        icon: Icons.sports_baseball_outlined,
                        value: _ballType,
                        items: _ballTypes,
                        onChanged: (v) => setState(() => _ballType = v),
                      ),
                      const SizedBox(height: 16),
                      _DropdownField(
                        label: 'PITCH TYPE',
                        icon: Icons.grass_rounded,
                        value: _pitchType,
                        items: _pitchTypes,
                        onChanged: (v) => setState(() => _pitchType = v),
                      ),
                      const SizedBox(height: 28),
                    ],
                  ),
                ),
              ),
            ),

            // â”€â”€ Sticky Bottom CTA â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            _BottomCta(onTap: _onNext),
          ],
        ),
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// HEADER
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _Header extends StatelessWidget {
  const _Header({required this.pulseAnim});
  final Animation<double> pulseAnim;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          // Back button
          Material(
            color: _Tokens.surface2,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: () => Navigator.maybePop(context),
              customBorder: const CircleBorder(),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppPalette.textPrimary),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'New Match',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppPalette.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedBuilder(
                      animation: pulseAnim,
                      builder: (context, child) => Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppPalette.accent.withValues(alpha: 0.4 + (pulseAnim.value * 0.6)),
                          boxShadow: [
                            BoxShadow(
                              color: AppPalette.accent.withValues(alpha: pulseAnim.value * 0.4),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Configure match settings and rules',
                  style: TextStyle(
                    fontSize: 13,
                    color: _Tokens.muted.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// STEP BAR
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _StepBar extends StatelessWidget {
  const _StepBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      color: _Tokens.surface1,
      child: Row(
        children: [
          _Step(label: 'Match Info', index: 1, state: _StepState.active),
          _StepConnector(filled: false),
          _Step(label: 'Squads', index: 2, state: _StepState.upcoming),
          _StepConnector(filled: false),
          _Step(label: 'Scoring', index: 3, state: _StepState.upcoming),
        ],
      ),
    );
  }
}

enum _StepState { done, active, upcoming }

class _Step extends StatelessWidget {
  const _Step({
    required this.label,
    required this.index,
    required this.state,
  });
  final String label;
  final int index;
  final _StepState state;

  @override
  Widget build(BuildContext context) {
    final isActive = state == _StepState.active;
    final isDone = state == _StepState.done;
    final Color dotColor = isDone
        ? AppPalette.success
        : isActive
            ? AppPalette.accent
            : _Tokens.muted;

    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? AppPalette.accent.withValues(alpha: 0.15)
                : isDone
                    ? AppPalette.success.withValues(alpha: 0.1)
                    : const Color(0xFF1A2A40),
            border: Border.all(color: dotColor, width: isActive ? 2 : 1.5),
            boxShadow: isActive
                ? [BoxShadow(color: AppPalette.accent.withValues(alpha: 0.4), blurRadius: 10, spreadRadius: 1)]
                : null,
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check_rounded, color: AppPalette.success, size: 14)
                : Text(
                    '$index',
                    style: TextStyle(
                      color: isActive ? AppPalette.accent : _Tokens.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            color: isActive ? AppPalette.accent : _Tokens.muted,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

class _StepConnector extends StatelessWidget {
  const _StepConnector({required this.filled});
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 1.5,
        margin: const EdgeInsets.only(bottom: 18, left: 6, right: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: filled
                ? [AppPalette.accent, AppPalette.accent.withValues(alpha: 0.3)]
                : [const Color(0xFF1E3050), const Color(0xFF1E3050)],
          ),
        ),
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// SECTION CARD
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// ─────────────────────────────────────────────────────────────────────────────
// SECTION HEADER
// ─────────────────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.icon,
  });
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 0, 14),
      child: Row(
        children: [
          Icon(icon, color: AppPalette.accent, size: 18),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: AppPalette.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// VALIDATED TEXT FIELD
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _ValidatedField extends StatefulWidget {
  const _ValidatedField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.validator,
    this.accentColor = AppPalette.accent,
    this.maxLength,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final String? Function(String?) validator;
  final Color accentColor;
  final int? maxLength;

  @override
  State<_ValidatedField> createState() => _ValidatedFieldState();
}

class _ValidatedFieldState extends State<_ValidatedField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: _Tokens.labelStyle),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: _focused ? _Tokens.surface3 : _Tokens.surface1,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _focused ? widget.accentColor : _Tokens.border,
              width: _focused ? 1.5 : 1,
            ),
            boxShadow: _focused
                ? [BoxShadow(color: widget.accentColor.withValues(alpha: 0.08), blurRadius: 10)]
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(width: 14),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Icon(
                  widget.icon,
                  key: ValueKey(_focused),
                  size: 17,
                  color: _focused ? widget.accentColor : _Tokens.muted,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Focus(
                  onFocusChange: (f) => setState(() => _focused = f),
                  child: TextFormField(
                    controller: widget.controller,
                    validator: widget.validator,
                    maxLength: widget.maxLength,
                    style: _Tokens.fieldStyle,
                    decoration: InputDecoration(
                      hintText: widget.hint,
                      hintStyle: TextStyle(
                        color: _Tokens.muted.withValues(alpha: 0.5),
                        fontSize: 15,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 15),
                      counterText: '',
                      errorStyle: const TextStyle(height: 0, fontSize: 0),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
            ],
          ),
        ),
        // (inline error is surfaced via TextFormField validator)
      ],
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// FORMAT PICKER
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _FormatPicker extends StatelessWidget {
  const _FormatPicker({
    required this.formats,
    required this.selected,
    required this.onSelect,
  });

  final List<(String, IconData, String)> formats;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('FORMAT', style: _Tokens.labelStyle),
        const SizedBox(height: 8),
        Row(
          children: formats.asMap().entries.map((e) {
            final i = e.key;
            final (label, icon, sub) = e.value;
            final sel = label == selected;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i < formats.length - 1 ? 8 : 0),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onSelect(label);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 68,
                    decoration: BoxDecoration(
                      color: sel
                          ? AppPalette.accent.withValues(alpha: 0.1)
                          : _Tokens.surface1,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: sel ? AppPalette.accent : _Tokens.border,
                        width: sel ? 1.5 : 1,
                      ),
                      boxShadow: sel
                          ? [
                              BoxShadow(
                                color: AppPalette.accent.withValues(alpha: 0.15),
                                blurRadius: 14,
                              )
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          icon,
                          size: 18,
                          color: sel ? AppPalette.accent : _Tokens.muted,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          label,
                          style: TextStyle(
                            color: sel ? AppPalette.accent : AppPalette.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          sub,
                          style: TextStyle(
                            color: sel
                                ? AppPalette.accent.withValues(alpha: 0.6)
                                : _Tokens.muted.withValues(alpha: 0.6),
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// CUSTOM OVERS ROW
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _CustomOversRow extends StatelessWidget {
  const _CustomOversRow({
    required this.oversCtrl,
    required this.ballsCtrl,
    required this.submitted,
  });
  final TextEditingController oversCtrl;
  final TextEditingController ballsCtrl;
  final bool submitted;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _NumberBox(
            controller: oversCtrl,
            label: 'Overs / Innings',
            hint: '20',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _NumberBox(
            controller: ballsCtrl,
            label: 'Balls / Over',
            hint: '6',
          ),
        ),
      ],
    );
  }
}

class _NumberBox extends StatelessWidget {
  const _NumberBox({
    required this.controller,
    required this.label,
    required this.hint,
  });
  final TextEditingController controller;
  final String label;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: AppPalette.textPrimary,
        fontSize: 22,
        fontWeight: FontWeight.w800,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: _Tokens.muted,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        hintText: hint,
        hintStyle: TextStyle(
          color: _Tokens.muted.withValues(alpha: 0.4),
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
        filled: true,
        fillColor: _Tokens.surface1,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _Tokens.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _Tokens.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppPalette.accent, width: 1.5),
        ),
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// VS DIVIDER
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _VsDivider extends StatelessWidget {
  const _VsDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Color(0xFF1E3050)],
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0060DD), Color(0xFF00AAEE)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppPalette.accent.withValues(alpha: 0.35),
                blurRadius: 14,
                spreadRadius: 0,
              )
            ],
          ),
          child: const Text(
            'VS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E3050), Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// TAPPABLE FIELD (Date / Time)
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _TapField extends StatelessWidget {
  const _TapField({
    required this.label,
    required this.icon,
    required this.hint,
    required this.onTap,
    required this.hasError,
    this.value,
  });

  final String label;
  final IconData icon;
  final String hint;
  final String? value;
  final bool hasError;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: _Tokens.labelStyle),
          const SizedBox(height: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 52,
            decoration: BoxDecoration(
              color: hasValue ? _Tokens.surface3 : _Tokens.surface1,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasError
                    ? _Tokens.error
                    : hasValue
                        ? AppPalette.accent.withValues(alpha: 0.5)
                        : _Tokens.border,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 13),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: hasValue ? AppPalette.accent : _Tokens.muted,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    value ?? hint,
                    style: TextStyle(
                      color: hasValue
                          ? AppPalette.textPrimary
                          : _Tokens.muted.withValues(alpha: 0.45),
                      fontSize: 13.5,
                      fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.expand_more_rounded,
                  size: 18,
                  color: hasValue
                      ? AppPalette.accent
                      : _Tokens.muted.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
          if (hasError)
            Padding(
              padding: const EdgeInsets.only(top: 5, left: 4),
              child: Text(
                '${label[0]}${label.substring(1).toLowerCase()} is required',
                style: const TextStyle(color: _Tokens.error, fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// DROPDOWN FIELD
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _Tokens.labelStyle),
        const SizedBox(height: 8),
        Container(
          height: 52,
          decoration: BoxDecoration(
            color: _Tokens.surface1,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _Tokens.border),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 13),
          child: Row(
            children: [
              Icon(icon, size: 17, color: _Tokens.muted),
              const SizedBox(width: 9),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: value,
                    isExpanded: true,
                    icon: const Icon(
                      Icons.expand_more_rounded,
                      color: AppPalette.accent,
                      size: 20,
                    ),
                    dropdownColor: const Color(0xFF0F2040),
                    style: _Tokens.fieldStyle,
                    items: items
                        .map(
                          (e) => DropdownMenuItem<String>(
                            value: e,
                            child: Text(e),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) onChanged(v);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// STICKY BOTTOM CTA
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _BottomCta extends StatefulWidget {
  const _BottomCta({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_BottomCta> createState() => _BottomCtaState();
}

class _BottomCtaState extends State<_BottomCta> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _Tokens.surface1,
        border: Border(top: BorderSide(color: _Tokens.border, width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) {
              setState(() => _pressed = false);
              widget.onTap();
            },
            onTapCancel: () => setState(() => _pressed = false),
            child: AnimatedScale(
              scale: _pressed ? 0.97 : 1.0,
              duration: const Duration(milliseconds: 100),
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _pressed
                        ? [const Color(0xFF0080BB), const Color(0xFF004FAA)]
                        : [const Color(0xFF00B4E8), const Color(0xFF0063D8)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppPalette.accent.withValues(alpha: _pressed ? 0.2 : 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Continue to Squads',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Step 1 of 3  Â·  All details can be edited before first ball',
            style: TextStyle(
              color: _Tokens.muted.withValues(alpha: 0.55),
              fontSize: 10.5,
              letterSpacing: 0.2,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

