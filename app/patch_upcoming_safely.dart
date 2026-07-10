// ignore_for_file: unused_local_variable
import 'dart:io';

void main() {
  final file = File('lib/screens/match/upcoming_fixtures_screen.dart');
  
  // Create a clean backup from git
  Process.runSync('git', ['checkout', 'lib/screens/match/upcoming_fixtures_screen.dart']);
  
  var content = file.readAsStringSync();
  content = content.replaceAll('\r\n', '\n');

  // Insert _handleDeleteMatch method
  if (!content.contains('Future<void> _handleDeleteMatch')) {
    final methodStr = '''  Future<void> _handleDeleteMatch(Match match) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppPalette.bgSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Match?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to permanently delete \${match.teamAId} vs \${match.teamBId}?',
          style: const TextStyle(color: AppPalette.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL', style: TextStyle(color: AppPalette.textMuted)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('DELETE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      try {
         await MatchService.deleteMatch(match.id);
         if (!mounted) return;
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Match deleted successfully')),
         );
         setState(() {
           _fixturesFuture = _loadFixtures();
         });
      } catch (e) {
         if (!mounted) return;
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Failed to delete match: \$e')),
         );
      }
    }
  }''';
    content = content.replaceFirst(
        '  Widget _buildHeader(BuildContext context) {',
        '\$methodStr\n\n  Widget _buildHeader(BuildContext context) {');
  }

  // Update _FixtureCard constructor
  content = content.replaceFirst(
      'class _FixtureCard extends StatelessWidget {\n  const _FixtureCard({required this.match});',
      'class _FixtureCard extends StatelessWidget {\n  const _FixtureCard({required this.match, required this.onDelete});\n\n  final VoidCallback onDelete;');

  // Inject trash icon after the match formatting on _FixtureCard
  content = content.replaceFirst(
'''                  child: Text(
                    match.matchFormat ?? 'T20',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                  ),
                ),
              ],
            ),
          ),''',
'''                  child: Text(
                    match.matchFormat ?? 'T20',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onDelete,
                  child: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),''');

  // Update _LiveFixtureCard constructor
  content = content.replaceFirst(
      'class _LiveFixtureCard extends StatelessWidget {\n  const _LiveFixtureCard({required this.match});',
      'class _LiveFixtureCard extends StatelessWidget {\n  const _LiveFixtureCard({required this.match, required this.onDelete});\n\n  final VoidCallback onDelete;');
      
  // Add delete icon after the LIVE tag and Match format on _LiveFixtureCard
  content = content.replaceFirst(
'''              Text(
                match.matchFormat?.toUpperCase() ?? 'MATCH',
                style: const TextStyle(
                  color: AppPalette.textMuted,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),''',
'''              Text(
                match.matchFormat?.toUpperCase() ?? 'MATCH',
                style: const TextStyle(
                  color: AppPalette.textMuted,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onDelete,
                child: const Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),''');

  // Inject onDelete to list views (Live Now loop)
  content = content.replaceFirst(
      '_LiveFixtureCard(match: match)',
      '_LiveFixtureCard(match: match, onDelete: () => _handleDeleteMatch(match))');

  // Inject onDelete to list views (Upcoming loop)
  content = content.replaceFirst(
      '_FixtureCard(match: match)',
      '_FixtureCard(match: match, onDelete: () => _handleDeleteMatch(match))');

  file.writeAsStringSync(content);
  print('Safe Patch complete');
}
