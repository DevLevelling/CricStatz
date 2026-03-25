-- =========================================================
-- Simple Career-Stats Schema (no season/format dimension)
-- =========================================================

-- UUID helper
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 1) Match records
CREATE TABLE IF NOT EXISTS public.match_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id UUID NOT NULL REFERENCES public.matches(id) ON DELETE CASCADE,
  team_a_id UUID NOT NULL REFERENCES public.teams(id),
  team_b_id UUID NOT NULL REFERENCES public.teams(id),
  format TEXT NOT NULL,
  venue TEXT,
  match_date TIMESTAMPTZ NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('completed', 'abandoned', 'no_result')),
  winning_team_id UUID REFERENCES public.teams(id),
  margin_type TEXT,
  margin_value INT,
  team_a_runs INT,
  team_a_wickets INT,
  team_a_overs TEXT,
  team_b_runs INT,
  team_b_wickets INT,
  team_b_overs TEXT,
  toss_winner_id UUID REFERENCES public.teams(id),
  toss_decision TEXT,
  man_of_match_id UUID REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_match_records_match_id ON public.match_records(match_id);
CREATE INDEX IF NOT EXISTS idx_match_records_team_a ON public.match_records(team_a_id);
CREATE INDEX IF NOT EXISTS idx_match_records_team_b ON public.match_records(team_b_id);
CREATE INDEX IF NOT EXISTS idx_match_records_date ON public.match_records(match_date);
CREATE INDEX IF NOT EXISTS idx_match_records_winner ON public.match_records(winning_team_id);

-- 2) Player career stats (one row per player)
CREATE TABLE IF NOT EXISTS public.player_career_stats (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID UNIQUE REFERENCES public.profiles(id) ON DELETE CASCADE,

  matches_played INT DEFAULT 0,
  innings INT DEFAULT 0,
  runs_scored INT DEFAULT 0,
  balls_faced INT DEFAULT 0,
  highest_score INT DEFAULT 0,
  fours INT DEFAULT 0,
  sixes INT DEFAULT 0,
  batting_avg NUMERIC(5,2) DEFAULT 0,
  strike_rate NUMERIC(6,2) DEFAULT 0,
  not_outs INT DEFAULT 0,

  bowling_matches INT DEFAULT 0,
  bowling_innings INT DEFAULT 0,
  runs_conceded INT DEFAULT 0,
  balls_bowled INT DEFAULT 0,
  wickets INT DEFAULT 0,
  best_figures TEXT,
  bowling_avg NUMERIC(6,2) DEFAULT 0,
  economy NUMERIC(5,2) DEFAULT 0,

  last_updated TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_player_career_stats_user ON public.player_career_stats(user_id);

-- 3) Player dismissals
CREATE TABLE IF NOT EXISTS public.player_dismissals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id UUID NOT NULL REFERENCES public.matches(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  how_out TEXT NOT NULL,
  bowler_id UUID REFERENCES public.profiles(id),
  fielder_id UUID REFERENCES public.profiles(id),
  ball_number INT,
  runs_at_dismissal INT,
  balls_faced INT,
  innings_number INT NOT NULL CHECK (innings_number IN (1,2)),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_player_dismissals_user ON public.player_dismissals(user_id);
CREATE INDEX IF NOT EXISTS idx_player_dismissals_match ON public.player_dismissals(match_id);

-- 4) Enhance player_stats for richer per-match detail
ALTER TABLE public.player_stats ADD COLUMN IF NOT EXISTS season TEXT;
ALTER TABLE public.player_stats ADD COLUMN IF NOT EXISTS format TEXT;
ALTER TABLE public.player_stats ADD COLUMN IF NOT EXISTS dismissal_mode TEXT;
ALTER TABLE public.player_stats ADD COLUMN IF NOT EXISTS dismissal_bowler_id UUID REFERENCES public.profiles(id);
ALTER TABLE public.player_stats ADD COLUMN IF NOT EXISTS dismissal_fielder_id UUID REFERENCES public.profiles(id);
ALTER TABLE public.player_stats ADD COLUMN IF NOT EXISTS innings_number INT;

-- 5) RLS
ALTER TABLE public.match_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.player_career_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.player_dismissals ENABLE ROW LEVEL SECURITY;

-- 6) Policies (idempotent)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname='public' AND tablename='match_records' AND policyname='match_records_select_all'
  ) THEN
    CREATE POLICY match_records_select_all
      ON public.match_records FOR SELECT USING (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname='public' AND tablename='player_career_stats' AND policyname='player_career_stats_select_all'
  ) THEN
    CREATE POLICY player_career_stats_select_all
      ON public.player_career_stats FOR SELECT USING (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname='public' AND tablename='player_dismissals' AND policyname='player_dismissals_select_all'
  ) THEN
    CREATE POLICY player_dismissals_select_all
      ON public.player_dismissals FOR SELECT USING (true);
  END IF;

  -- Needed if your Flutter app writes these tables with authenticated users
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname='public' AND tablename='match_records' AND policyname='match_records_write_auth'
  ) THEN
    CREATE POLICY match_records_write_auth
      ON public.match_records FOR ALL TO authenticated
      USING (true) WITH CHECK (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname='public' AND tablename='player_career_stats' AND policyname='player_career_stats_write_auth'
  ) THEN
    CREATE POLICY player_career_stats_write_auth
      ON public.player_career_stats FOR ALL TO authenticated
      USING (true) WITH CHECK (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname='public' AND tablename='player_dismissals' AND policyname='player_dismissals_write_auth'
  ) THEN
    CREATE POLICY player_dismissals_write_auth
      ON public.player_dismissals FOR ALL TO authenticated
      USING (true) WITH CHECK (true);
  END IF;
END $$;
