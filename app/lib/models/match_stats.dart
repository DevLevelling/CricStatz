class BatsmanScore {
  final String name;
  final String runs;
  final String balls;
  final int fours;
  final int sixes;
  final String sr;
  final bool? isActive;
  final String? imageUrl;
  final String? dismissal;

  const BatsmanScore({
    required this.name,
    required this.runs,
    required this.balls,
    required this.fours,
    required this.sixes,
    required this.sr,
    this.isActive,
    this.imageUrl,
    this.dismissal,
  });

  factory BatsmanScore.fromJson(Map<String, dynamic> json) {
    return BatsmanScore(
      name: json['name'] as String,
      runs: json['runs'].toString(),
      balls: json['balls'].toString(),
      fours: json['fours'] as int,
      sixes: json['sixes'] as int,
      sr: json['sr'].toString(),
      isActive: json['is_active'] as bool?,
      imageUrl: json['image_url'] as String?,
      dismissal: json['dismissal'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'runs': runs,
        'balls': balls,
        'fours': fours,
        'sixes': sixes,
        'sr': sr,
        'is_active': isActive,
        'image_url': imageUrl,
        'dismissal': dismissal,
      };
}

class BowlerScore {
  final String name;
  final String overs;
  final String maidens;
  final String runs;
  final String wickets;
  final String econ;
  final List<String>? currentOverBalls;
  final String? imageUrl;

  const BowlerScore({
    required this.name,
    required this.overs,
    required this.maidens,
    required this.runs,
    required this.wickets,
    required this.econ,
    this.currentOverBalls,
    this.imageUrl,
  });

  factory BowlerScore.fromJson(Map<String, dynamic> json) {
    return BowlerScore(
      name: json['name'] as String,
      overs: json['overs'].toString(),
      maidens: json['maidens'].toString(),
      runs: json['runs'].toString(),
      wickets: json['wickets'].toString(),
      econ: json['econ'].toString(),
      currentOverBalls: (json['current_over_balls'] as List?)?.map((e) => e.toString()).toList(),
      imageUrl: json['image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'overs': overs,
        'maidens': maidens,
        'runs': runs,
        'wickets': wickets,
        'econ': econ,
        'current_over_balls': currentOverBalls,
        'image_url': imageUrl,
      };
}

class Partnership {
  final String runs;
  final String balls;

  const Partnership({required this.runs, required this.balls});

  factory Partnership.fromJson(Map<String, dynamic> json) {
    return Partnership(
      runs: json['runs'].toString(),
      balls: json['balls'].toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'runs': runs,
        'balls': balls,
      };
}

class ScoreSummary {
  final String inningsName;
  final String runs;
  final String wickets;
  final String overs;
  final String crr;
  final String? target;
  final String? reqRate;
  final String? summaryText;
  final String? battingTeam;
  final Map<String, dynamic>? firstInnings;
  final List<dynamic>? allBowlers;
  final int? squadSize;

  const ScoreSummary({
    required this.inningsName,
    required this.runs,
    required this.wickets,
    required this.overs,
    required this.crr,
    this.target,
    this.reqRate,
    this.summaryText,
    this.battingTeam,
    this.firstInnings,
    this.allBowlers,
    this.squadSize,
  });

  Map<String, dynamic> toJson() => {
        'innings_name': inningsName,
        'runs': runs,
        'wickets': wickets,
        'overs': overs,
        'crr': crr,
        'target': target,
        'req_rate': reqRate,
        'summary_text': summaryText,
        'batting_team': battingTeam,
        'first_innings': firstInnings,
        'all_bowlers': allBowlers,
        'squad_size': squadSize,
      };

  factory ScoreSummary.fromJson(Map<String, dynamic> json) {
    return ScoreSummary(
      inningsName: json['innings_name'] as String,
      runs: json['runs'].toString(),
      wickets: json['wickets'].toString(),
      overs: json['overs'].toString(),
      crr: json['crr'].toString(),
      target: json['target']?.toString(),
      reqRate: json['req_rate']?.toString(),
      summaryText: json['summary_text'] as String?,
      battingTeam: json['batting_team'] as String?,
      firstInnings: json['first_innings'] as Map<String, dynamic>?,
      allBowlers: json['all_bowlers'] as List<dynamic>?,
      squadSize: json['squad_size'] as int?,
    );
  }
}
