# Live Scoring Screen Architecture Fixes

## Overview
Fixed the fundamental architectural issues in `scoreliveupdate.dart` that caused placeholder logic, hardcoded players, and improper match state persistence.

## Problems Solved

### 1. **Hardcoded Player Names** ✅
**Before:** Batsmen and bowlers showed fixed names ("S. Gopi", "R. Sharma", "M. Starc")
**After:** 
- Fetches actual player names from backend via `TeamService.getTeamPlayers()`
- Properly maps batting and bowling team players based on toss decision
- Updates UI with real player data from database

### 2. **Placeholder Run Division Logic** ✅
**Before:** Used arithmetic `(_runs ~/ 2)` to guess striker vs non-striker runs
**After:**
- Tracks individual batsman runs in `_playerStats` map
- Each run attributed to the actual striker when scored
- Maintains historic accuracy: every run tagged to the player who scored it

### 3. **Hardcoded Ball Counts** ✅
**Before:** Striker showed "12 balls" and non-striker "15 balls" (static values)
**After:**
- Each batsman's ball count incremented with every legal ball delivered
- Accurate strike rate calculated: `(runs / balls) * 100`
- Updates live as batsmen accumulate balls faced

### 4. **Lost Wicket Attribution** ✅
**Before:** Wickets only incremented global counter, no dismissal record
**After:**
- Wicket selection dialog shows actual batting team players
- Selected player marked `out: true` in `_playerStats`
- Wicket attributed to current bowler with lookup in player stats
- Proper bowler figures tracked: Overs-Maidens-Runs-Wickets

### 5. **No Batsman Rotation After Dismissal** ✅
**Before:** After dismissal, UI showed same first 2 batsmen indefinitely
**After:**
- New `_rotateNextBatsman()` method finds next available batsman
- Non-striker promoted to striker position
- System finds next unbatted player automatically
- Detects all-out condition when no more batsmen available

### 6. **Lost First Innings Data** ✅
**Before:** 1st innings runs discarded when starting 2nd innings
**After:**
- Saves `_firstInningsRuns` before resetting counters
- 2nd innings context knows 1st innings total for run chase scenarios
- Can calculate deficit/lead between innings

### 7. **No Undo Support for Player Stats** ✅
**Before:** Undo only restored team scores and overs, lost per-player state
**After:**
- `_saveHistory()` captures full player stats snapshot + batsman/bowler indices
- `_undo()` restores complete match state including all per-player data
- Undo/redo cycles maintain historical accuracy

### 8. **Static Bowler Display** ✅
**Before:** Always showed first bowler with hardcoded figures "2-0-14-1, econ 7.0"
**After:**
- Current bowling index tracked in `_bowlerIndex`
- Bowler figures calculated from actual stats: overs bowled, runs conceded, wickets taken
- Economy rate computed: `(runs_conceded / (balls_bowled / 6))`
- Updates dynamically as bowler delivers balls

## Architecture Changes

### State Management Improvements
```dart
// NEW: Per-player statistics tracking
Map<String, Map<String, dynamic>> _playerStats = {
  player.id: {
    'runs': 0,           // Runs scored
    'balls': 0,          // Balls faced
    'fours': 0,          // Number of fours
    'sixes': 0,          // Number of sixes
    'sr': '0.0',         // Strike rate
    'out': false,        // Dismissal status
    'balls_bowled': 0,   // For bowlers
    'wickets': 0,        // Wickets taken
    'economy': '0.0',    // Economy rate
  }
};

// NEW: Current player position tracking
int _strikerIndex = 0;           // Index of current striker
int _nonStrikerIndex = 1;        // Index of current non-striker
int _bowlerIndex = 0;            // Index of current bowler

// Preserved: First innings total
int _firstInningsRuns = 0;
```

### Key Methods Updated

#### 1. `_fetchBattingTeamPlayers()`
- Initializes player stats for all batting team players
- Sets all stats to zero at match start
- Prevents "No players available" error by ensuring players load before sync

#### 2. `_applyBall()`
- Updates striker's runs and balls faced
- Tracks fours (4 runs) and sixes (6 runs) separately
- Calculates strike rate: `(runs / balls) * 100`
- Updates bowler's balls bowled and runs conceded statistics
- Properly handles legal vs. illegal balls

#### 3. `_startSecondInnings()`
- Saves `_firstInningsRuns` before resetting
- Clears player stats for new batting team
- Resets indices: `_strikerIndex = 0`, `_nonStrikerIndex = 1`, `_bowlerIndex = 0`
- Refetches new batting team players from backend

#### 4. `_finalizeWicket()` + `_rotateNextBatsman()`
- Marks dismissed player with `out: true`
- Attributes wicket to current bowler by incrementing `bowler.wickets`
- Rotates batsmen: moving non-striker to striker
- Finds next available batsman by scanning forward
- Handles all-out condition detection

#### 5. `_syncScore()`
- Uses actual player objects from index tracking
- Reads per-player stats from `_playerStats` dictionary
- Calculates bowler economy rate properly
- Syncs real state to backend live_scores record

#### 6. `_buildBatsmanStats()` + `_buildBowlerStats()`
- Uses `_strikerIndex` and `_nonStrikerIndex` for current players
- Displays actual stats from `_playerStats` (not hardcoded values)
- Shows calculated strike rates and figures
- Updates UI reactively as stats change

### History and Undo System
```dart
_saveHistory() stores:
- Team score, wickets, overs
- Batsman/bowler indices
- Complete player stats snapshot
- Recent balls history

_undo() restores:
- All state variables
- Full player stats by value
- Current striker/non-striker/bowler positions
```

## Data Flow Improvements

### Match Initialization
```
Match Start 
  → Determine batting/bowling team IDs from toss decision
  → _fetchBattingTeamPlayers() - fetch from backend
  → Initialize _playerStats for all players
  → _syncScore() creates live_scores record
  → UI displays real player names
```

### Scoring Event Flow
```
User taps "+1" button (runs)
  → _applyBall(runDelta: 1)
    → Update _playerStats[striker_id]['runs']++
    → Update _playerStats[striker_id]['balls']++
    → Recalculate strike rate
    → Update _playerStats[bowler_id]['balls_bowled']++
    → Update _playerStats[bowler_id]['runs']++
  → _saveHistory() stores full state
  → _syncScore() persists to backend
  → _buildBatsmanStats() displays updated values
```

### Wicket Flow
```
User selects "Wicket" → chooses player
  → _finalizeWicket(type, playerName)
    → Mark _playerStats[player_id]['out'] = true
    → Increment _playerStats[bowler_id]['wickets']
    → _rotateNextBatsman()
      → _strikerIndex = _nonStrikerIndex
      → Find next available (not dismissed)
      → Set _nonStrikerIndex to new batsman
    → _applyBall(isWicket: true)
  → _syncScore() records dismissal
  → UI rotates to show new batsmen
```

### Innings Transition
```
Overs limit reached or match complete
  → _startSecondInnings()
    → Save _firstInningsRuns = _runs
    → Reset _runs, _wickets, _overs to 0
    → Swap team IDs (batting ↔ bowling)
    → Clear _playerStats
    → _fetchBattingTeamPlayers() for new batting team
    → Re-initialize _playerStats for new team
    → Reset indices
  → _syncScore() syncs 2nd innings context
```

## Testing Recommendations

### Unit Tests
- [ ] Per-player stats increment correctly on each ball
- [ ] Strike rate calculated accurately: (runs/balls)*100
- [ ] Batsman rotation selects correct next player
- [ ] All-out detected when no players remain
- [ ] First innings total preserved to second innings
- [ ] Undo/redo cycle maintains accurate state

### Integration Tests
- [ ] Team players fetched at match start
- [ ] Wicket attributed to both dismissed batsman and bowler
- [ ] UI displays actual player stats (not hardcoded)
- [ ] Backend live_scores record updated with real data
- [ ] Innings transition saves state properly

### Manual Testing Checklist
- [ ] Start match → verify actual team players displayed (not "S. Gopi", "R. Sharma")
- [ ] Score runs → verify attributed to current striker, not divided by 2
- [ ] Register wicket → verify dismissed player shown, next batsman appears
- [ ] Complete 1st innings → verify score saved for 2nd innings context
- [ ] Navigate away and back → verify state persisted in undo history
- [ ] Check backend → verify live_scores record contains real batsman/bowler data

## Performance Implications
- **Minimal overhead:** Player stats stored in Map, accessed O(1) by player ID
- **Reasonable memory:** Single Map<String, Map> per match instance
- **Accurate history:** Complete state captured per ball (enables detailed analytics)
- **Backend sync:** No additional API calls (uses existing updateLiveScore endpoint)

## Future Enhancements
1. **Bowler rotation:** Track multiple bowlers and allow switching
2. **Extras tracking:** Wides, no-balls, byes, leg-byes separate tracking
3. **Partnership tracking:** Cumulative runs and balls for current partnership
4. **Player-wise analysis:** Store runs by type (singles, fours, sixes) per player
5. **Innings resumption:** Allow saving incomplete innings and resuming later
6. **Match statistics:** Generate accurate reports from tracked per-player data

## Files Modified
- `lib/screens/match/scoreliveupdate.dart` - All core logic changes

## Breaking Changes
- None - Existing Supabase schema unchanged
- Backend `live_scores` records now contain accurate player-level statistics
- No UI breaking changes (displays same information, sourced accurately)

---

**Summary:** The live scoring system now tracks real match state accurately, attributes runs/wickets to specific players, rotates batsmen after dismissals, and persists all state both in-memory and to the backend. Every action reflects ground reality instead of placeholder logic.
