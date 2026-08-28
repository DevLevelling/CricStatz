import 'package:cricstatz/config/palette.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '';
  String _buildNumber = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() { _version = info.version; _buildNumber = info.buildNumber; });
    });
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open link')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppPalette.bgPrimary,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: AppPalette.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('About CricStatz', style: TextStyle(color: AppPalette.textPrimary, fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),
            Center(child: Column(children: [
              Container(
                width: 88, height: 88,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppPalette.accent, AppPalette.progress], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(Icons.sports_cricket_rounded, size: 48, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text('CricStatz', style: TextStyle(color: AppPalette.textPrimary, fontSize: 24, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(_version.isEmpty ? 'Loading...' : 'Version $_version ($_buildNumber)', style: TextStyle(color: AppPalette.textMuted, fontSize: 13)),
            ])),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _SectionLabel('About'),
                _Card(children: [
                  _InfoRow(Icons.sports_cricket_rounded, 'Description', 'CricStatz is a live cricket scoring and statistics app for amateur and club cricketers.'),
                  Divider(height: 1, indent: 48, color: AppPalette.cardStroke),
                  _InfoRow(Icons.code_rounded, 'Developer', 'DevLevelling Team'),
                ]),
                const SizedBox(height: 24),
                _SectionLabel('Legal'),
                _Card(children: [
                  _LinkRow(Icons.privacy_tip_outlined, 'Privacy Policy', () => _openUrl('https://github.com/DevLevelling/CricStatz#privacy-policy')),
                  Divider(height: 1, indent: 48, color: AppPalette.cardStroke),
                  _LinkRow(Icons.description_outlined, 'Terms of Service', () => _openUrl('https://github.com/DevLevelling/CricStatz#terms')),
                ]),
                const SizedBox(height: 24),
                _SectionLabel('Connect'),
                _Card(children: [
                  _LinkRow(Icons.feedback_outlined, 'Send Feedback', () => _openUrl('mailto:support@cricstatz.com?subject=CricStatz%20Feedback')),
                  Divider(height: 1, indent: 48, color: AppPalette.cardStroke),
                  _LinkRow(Icons.code_outlined, 'View on GitHub', () => _openUrl('https://github.com/DevLevelling/CricStatz')),
                ]),
                const SizedBox(height: 48),
                Center(child: Text('© 2025 DevLevelling. All rights reserved.', style: TextStyle(color: AppPalette.textSubtle, fontSize: 12))),
                const SizedBox(height: 32),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  const _SectionLabel(this.title);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(title.toUpperCase(), style: TextStyle(color: AppPalette.textMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
  );
}

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: AppPalette.cardPrimary, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppPalette.cardStroke)),
    child: Column(children: children),
  );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  const _InfoRow(this.icon, this.title, this.subtitle);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: AppPalette.accent, size: 20),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(color: AppPalette.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 2),
        Text(subtitle, style: TextStyle(color: AppPalette.textMuted, fontSize: 13)),
      ])),
    ]),
  );
}

class _LinkRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const _LinkRow(this.icon, this.title, this.onTap);
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Icon(icon, color: AppPalette.accent, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(title, style: TextStyle(color: AppPalette.textPrimary, fontWeight: FontWeight.w600, fontSize: 14))),
        Icon(Icons.chevron_right, color: AppPalette.textMuted, size: 20),
      ]),
    ),
  );
}
