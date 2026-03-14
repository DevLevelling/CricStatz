-- Create a simple table to store total downloads manually or programmatically.
CREATE TABLE IF NOT EXISTS public.app_metrics (
    id SERIAL PRIMARY KEY,
    key_name TEXT UNIQUE NOT NULL,
    value_count BIGINT NOT NULL DEFAULT 0
);

-- Insert initial "total_downloads" row if it doesn't exist.
INSERT INTO public.app_metrics (key_name, value_count)
VALUES ('total_downloads', 2000) -- You can change 2000 to whatever your current downloads are
ON CONFLICT (key_name) DO NOTHING;

-- Create an RPC function that the anon client can call to securely get these stats.
-- Security DEFINER means it can read auth.users safely on behalf of the caller.
CREATE OR REPLACE FUNCTION get_app_metrics()
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_total_downloads BIGINT;
    v_registered_users BIGINT;
    v_active_users_30d BIGINT;
    v_daily_logins BIGINT;
BEGIN
    -- 1. Total Downloads from app_metrics table
    SELECT COALESCE(value_count, 0) INTO v_total_downloads
    FROM public.app_metrics
    WHERE key_name = 'total_downloads'
    LIMIT 1;

    -- If no row found, default it purely for safety
    IF v_total_downloads IS NULL THEN
        v_total_downloads := 2000;
    END IF;

    -- 2. Total Registered Users using your 'profiles' table!
    -- Joining with auth.users to ensure we only count unique email addresses
    SELECT COUNT(DISTINCT au.email) INTO v_registered_users
    FROM public.profiles p
    JOIN auth.users au ON p.id = au.id;

    -- 3. Active Users (Monthly Active Users - MAU)
    -- People who actually opened or used the app in the last 30 days
    -- We use 'last_sign_in_at' from auth.users to measure real engagement
    SELECT COUNT(DISTINCT au.email) INTO v_active_users_30d
    FROM public.profiles p
    JOIN auth.users au ON p.id = au.id
    WHERE au.last_sign_in_at > (NOW() - INTERVAL '30 days');

    -- 4. Daily Logins (Daily Active Users - DAU)
    -- People who actually opened or used the app in the last 24 hours
    SELECT COUNT(DISTINCT au.email) INTO v_daily_logins
    FROM public.profiles p
    JOIN auth.users au ON p.id = au.id
    WHERE au.last_sign_in_at > (NOW() - INTERVAL '24 hours');

    -- Return as a JSON object
    RETURN json_build_object(
        'total_downloads', COALESCE(v_total_downloads, 0),
        'registered_users', COALESCE(v_registered_users, 0),
        'active_users', COALESCE(v_active_users_30d, 0),
        'daily_logins', COALESCE(v_daily_logins, 0)
    );
END;
$$;

-- Create an RPC function to securely increment the total downloads count
CREATE OR REPLACE FUNCTION increment_downloads()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE public.app_metrics
    SET value_count = value_count + 1
    WHERE key_name = 'total_downloads';
END;
$$;
