-- ============================================================
-- contco Workbench — shared database schema
-- Run this once in Supabase: Dashboard -> SQL Editor -> New query -> paste -> Run
-- ============================================================

-- 1) Team-added pages (shared across the team)
create table if not exists custom_pages (
  id          text primary key,         -- e.g. 'custom::1780...'
  code        text,                     -- e.g. 'NEW7'
  name        text not null,
  section     text default '7 · New / Build',  -- which banner/heading it sits under
  subsection  text default '',
  created_at  timestamptz default now()
);
-- add the section column if the table already existed without it
alter table custom_pages add column if not exists section text default '7 · New / Build';

-- 2) Left ("updated") and right ("new") HTML drafts — one per side, per page
create table if not exists drafts (
  page_id     text not null,            -- file name for captured pages, or custom id
  side        text not null check (side in ('left','right')),
  html        text default '',
  updated_at  timestamptz default now(),
  primary key (page_id, side)
);

-- 3) Repair notes / comments
create table if not exists notes (
  id          uuid primary key default gen_random_uuid(),
  page_id     text not null,
  title       text default '',
  message     text default '',
  priority    text default 'P2',        -- P1 / P2 / P3
  status      text default '',          -- '' / 'pass' / 'fail'
  created_at  timestamptz default now()
);

-- Full row data on changes so realtime deletes know which page they belonged to
alter table custom_pages replica identity full;
alter table drafts       replica identity full;
alter table notes        replica identity full;

-- Row Level Security ON, with OPEN policies for now (anyone with the anon key).
-- We'll tighten this to team logins / Cloudflare Access in the next step.
alter table custom_pages enable row level security;
alter table drafts       enable row level security;
alter table notes        enable row level security;

drop policy if exists "open custom_pages" on custom_pages;
drop policy if exists "open drafts"       on drafts;
drop policy if exists "open notes"        on notes;
create policy "open custom_pages" on custom_pages for all using (true) with check (true);
create policy "open drafts"       on drafts       for all using (true) with check (true);
create policy "open notes"        on notes        for all using (true) with check (true);

-- Enable realtime (live sync) on the three tables
alter publication supabase_realtime add table custom_pages;
alter publication supabase_realtime add table drafts;
alter publication supabase_realtime add table notes;


-- contco Workbench — shared JOBS table (run once in Supabase SQL Editor)
-- Jobs are team-shared and feed the Job Board. Until this runs, jobs still work
-- (they save locally per browser); after it runs, they sync to the whole team.

create table if not exists jobs (
  id          text primary key,         -- 'job-...'
  page_id     text not null,            -- which page/email the job belongs to
  title       text default '',
  type        text default 'repair',    -- repair | build
  priority    text default 'P2',        -- P1 | P2 | P3
  stage       text default 'todo',      -- todo|in_progress|ready|passed|live|deferred
  action      text default '',          -- what to do / test
  expected    text default '',          -- expected result
  actual      text default '',          -- actual result (filled when tested)
  created_at  timestamptz default now()
);

alter table jobs replica identity full;
alter table jobs enable row level security;
drop policy if exists "open jobs" on jobs;
create policy "open jobs" on jobs for all using (true) with check (true);
alter publication supabase_realtime add table jobs;
