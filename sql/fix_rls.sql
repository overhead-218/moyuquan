-- Fix RLS policies for posts and profiles to allow anon read
-- This replaces restrictive policies that block anonymous SELECT

-- Posts table
DROP POLICY IF EXISTS "anon_read_posts" ON posts;
CREATE POLICY "anon_read_posts" ON posts FOR SELECT USING (true);

DROP POLICY IF EXISTS "anon_insert_posts" ON posts;
CREATE POLICY "anon_insert_posts" ON posts FOR INSERT WITH CHECK (true);

-- Profiles table  
DROP POLICY IF EXISTS "anon_read_profiles" ON profiles;
CREATE POLICY "anon_read_profiles" ON profiles FOR SELECT USING (true);

DROP POLICY IF EXISTS "anon_insert_profiles" ON profiles;
CREATE POLICY "anon_insert_profiles" ON profiles FOR INSERT WITH CHECK (true);

-- Messages table (may also need fix)
DROP POLICY IF EXISTS "anon_read_messages" ON messages;
CREATE POLICY "anon_read_messages" ON messages FOR SELECT USING (true);

DROP POLICY IF EXISTS "anon_insert_messages" ON messages;
CREATE POLICY "anon_insert_messages" ON messages FOR INSERT WITH CHECK (true);

-- Spots table
DROP POLICY IF EXISTS "anon_read_spots" ON spots;
CREATE POLICY "anon_read_spots" ON spots FOR SELECT USING (true);

DROP POLICY IF EXISTS "anon_insert_spots" ON spots;
CREATE POLICY "anon_insert_spots" ON spots FOR INSERT WITH CHECK (true);
