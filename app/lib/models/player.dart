class Player {
  final String id;
  final String teamId;
  final String name;
  final String role;

  const Player({
    required this.id,
    required this.teamId,
    required this.name,
    required this.role,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'team_id': teamId,
        'name': name,
        'role': role,
      };

  factory Player.fromJson(Map<String, dynamic> json) {
    final teamId = (json['team_id'] ?? '').toString();
    final name = (json['name'] ?? '').toString().trim();
    final fallbackId = teamId.isNotEmpty
        ? '${teamId}_${name.isNotEmpty ? name : 'player'}'
        : (name.isNotEmpty ? name : 'player');

    return Player(
      id: (json['id'] ?? fallbackId).toString(),
      teamId: teamId,
      name: name.isNotEmpty ? name : 'Unknown Player',
      role: (json['role'] ?? 'Player').toString(),
    );
  }
}
