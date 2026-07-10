// ignore_for_file: unused_local_variable
import 'dart:io';

void main() {
  final file = File('lib/screens/match/upcoming_fixtures_screen.dart');
  var content = file.readAsStringSync();
  content = content.replaceAll('\r\n', '\n');

  // Insert _handleDeleteMatch method into _UpcomingFixturesScreenState
  if (!content.contains('Future<void> _handleDeleteMatch')) {
    final methodStr = '''  
  Future<void> _handleDeleteMatch(Match match) async {
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

  // Update _FixtureCard class definition
  content = content.replaceFirst(
      'class _FixtureCard extends StatelessWidget {\n  const _FixtureCard({required this.match});',
      'class _FixtureCard extends StatelessWidget {\n  const _FixtureCard({required this.match, required this.onDelete});\n\n  final VoidCallback onDelete;');

  // Add delete icon to _FixtureCard
  if (!content.contains('onTap: onDelete,')) {
    content = content.replaceFirst(
        '],\n            ),\n          ),\n          const Divider(height: 1, color: Color(0xFF2D3748)),',
        '  const SizedBox(width: 8),\n                GestureDetector(\n                  onTap: onDelete,\n                  child: const Icon(\n                    Icons.delete_outline,\n                    color: Colors.redAccent,\n                    size: 18,\n                  ),\n                ),\n              ],\n            ),\n          ),\n          const Divider(height: 1, color: Color(0xFF2D3748)),');
  }

  // Update _LiveFixtureCard class definition
  content = content.replaceFirst(
      'class _LiveFixtureCard extends StatelessWidget {\n  const _LiveFixtureCard({required this.match});',
      'class _LiveFixtureCard extends StatelessWidget {\n  const _LiveFixtureCard({required this.match, required this.onDelete});\n\n  final VoidCallback onDelete;');
      
  // Add delete icon to _LiveFixtureCard
  content = content.replaceFirst(
      '),\n            ],\n          ),\n          const SizedBox(height: 10),',
      '),\n              const SizedBox(width: 8),\n              GestureDetector(\n                onTap: onDelete,\n                child: const Icon(\n                  Icons.delete_outline,\n                  color: Colors.redAccent,\n                  size: 18,\n                ),\n              ),\n            ],\n          ),\n          const SizedBox(height: 10),');

  // Inject onDelete to list views
  content = content.replaceFirst(
      '_LiveFixtureCard(\n                                  match: match,',
      '_LiveFixtureCard(\n                                  match: match,\n                                  onDelete: () => _handleDeleteMatch(match),');

  content = content.replaceFirst(
      '_FixtureCard(\n                                match: match,',
      '_FixtureCard(\n                                match: match,\n                                onDelete: () => _handleDeleteMatch(match),');

  file.writeAsStringSync(content);
  print('Patch complete');
}
