import 'package:cricstatz/config/palette.dart';
import 'package:cricstatz/config/routes.dart';
import 'package:cricstatz/providers/team_provider.dart';
import 'package:cricstatz/widgets/app_bottom_nav_bar.dart';
import 'package:cricstatz/widgets/app_header.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TeamListScreen extends StatefulWidget {
  const TeamListScreen({super.key});

  @override
  State<TeamListScreen> createState() => _TeamListScreenState();
}

class _TeamListScreenState extends State<TeamListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TeamProvider>().loadTeams();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: AppBottomNavBar(currentIndex: 2),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.createTeam),
        backgroundColor: AppPalette.accent,
        foregroundColor: AppPalette.bgSecondary,
        child: const Icon(Icons.add),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: AppPalette.surfaceGradient),
        child: SafeArea(
          child: Column(
            children: [
              AppHeader(
                trailing: IconButton(
                  icon: Icon(Icons.refresh, color: AppPalette.textPrimary),
                  onPressed: () => context.read<TeamProvider>().loadTeams(),
                ),
              ),
              Expanded(
                child: Consumer<TeamProvider>(
                  builder: (context, teamProvider, _) {
                    if (teamProvider.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (teamProvider.error != null) {
                      return Center(
                        child: Text(
                          'Error: ${teamProvider.error}',
                          style: TextStyle(color: AppPalette.live),
                        ),
                      );
                    }

                    final teams = teamProvider.teams;
                    if (teams.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.group_outlined, size: 64, color: AppPalette.textMuted),
                            const SizedBox(height: 16),
                            Text(
                              'No teams found',
                              style: TextStyle(
                                color: AppPalette.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Create a team to start setting up squads.',
                              style: TextStyle(color: AppPalette.textMuted),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: teams.length,
                      itemBuilder: (context, index) {
                        final team = teams[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          color: AppPalette.cardPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: AppPalette.cardStroke),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor: AppPalette.accent.withValues(alpha: 0.1),
                              child: Text(
                                team.shortCode.toUpperCase(),
                                style: TextStyle(
                                  color: AppPalette.accent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              team.name,
                              style: TextStyle(
                                color: AppPalette.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              'Code: ${team.shortCode}',
                              style: TextStyle(color: AppPalette.textMuted),
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.delete_outline, color: AppPalette.live),
                              onPressed: () => _confirmDelete(context, teamProvider, team.id, team.name),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, TeamProvider provider, String teamId, String teamName) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppPalette.bgSecondary,
        title: Text('Delete $teamName?', style: TextStyle(color: AppPalette.textPrimary)),
        content: Text('Are you sure you want to delete this team?', style: TextStyle(color: AppPalette.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: AppPalette.textMuted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.deleteTeam(teamId);
            },
            child: Text('Delete', style: TextStyle(color: AppPalette.live)),
          ),
        ],
      ),
    );
  }
}
