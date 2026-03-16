class Match {
  final String id;
  final String teamAId;
  final String teamBId;
  final String? venue;
  final String? matchFormat;
  final DateTime? matchDate;
  final int oversLimit;
  final String status;
  final String? tossWinner;
  final String? tossDecision;
  final String? venueCity;
  final String? venueCapacity;
  final String? venueEnds;
  final String? weatherTemp;
  final String? weatherDesc;
  final String? humidity;
  final String? pitchType;
  final String? pitchDesc;
  final int? paceRatio;
  final int? spinRatio;
  final int? headToHeadA;
  final int? headToHeadB;
  final List<String>? teamASquad;
  final List<String>? teamBSquad;
  final DateTime? createdAt;

  const Match({
    required this.id,
    required this.teamAId,
    required this.teamBId,
    this.venue,
    this.matchFormat,
    this.matchDate,
    required this.oversLimit,
    required this.status,
    this.tossWinner,
    this.tossDecision,
    this.venueCity,
    this.venueCapacity,
    this.venueEnds,
    this.weatherTemp,
    this.weatherDesc,
    this.humidity,
    this.pitchType,
    this.pitchDesc,
    this.paceRatio,
    this.spinRatio,
    this.headToHeadA,
    this.headToHeadB,
    this.teamASquad,
    this.teamBSquad,
    this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'team_a_id': teamAId,
        'team_b_id': teamBId,
        'venue': venue,
        'match_format': matchFormat,
        'match_date': matchDate?.toIso8601String(),
        'overs_limit': oversLimit,
        'status': status,
        'toss_winner': tossWinner,
        'toss_decision': tossDecision,
        'venue_city': venueCity,
        'venue_capacity': venueCapacity,
        'venue_ends': venueEnds,
        'weather_temp': weatherTemp,
        'weather_desc': weatherDesc,
        'humidity': humidity,
        'pitch_type': pitchType,
        'pitch_desc': pitchDesc,
        'pace_ratio': paceRatio,
        'spin_ratio': spinRatio,
        'head_to_head_a': headToHeadA,
        'head_to_head_b': headToHeadB,
        'team_a_squad': teamASquad,
        'team_b_squad': teamBSquad,
        'created_at': createdAt?.toIso8601String(),
      };

  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      id: json['id'] as String,
      teamAId: json['team_a_id'] as String,
      teamBId: json['team_b_id'] as String,
      venue: json['venue'] as String?,
      matchFormat: json['match_format'] as String?,
      matchDate: json['match_date'] != null 
          ? DateTime.parse(json['match_date'] as String) 
          : null,
      oversLimit: (json['overs_limit'] as num).toInt(),
      status: json['status'] as String,
      tossWinner: json['toss_winner'] as String?,
      tossDecision: json['toss_decision'] as String?,
      venueCity: json['venue_city'] as String?,
      venueCapacity: json['venue_capacity'] as String?,
      venueEnds: json['venue_ends'] as String?,
      weatherTemp: json['weather_temp'] as String?,
      weatherDesc: json['weather_desc'] as String?,
      humidity: json['humidity'] as String?,
      pitchType: json['pitch_type'] as String?,
      pitchDesc: json['pitch_desc'] as String?,
      paceRatio: json['pace_ratio'] as int?,
      spinRatio: json['spin_ratio'] as int?,
      headToHeadA: json['head_to_head_a'] as int?,
      headToHeadB: json['head_to_head_b'] as int?,
      teamASquad: (json['team_a_squad'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      teamBSquad: (json['team_b_squad'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }
}
