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
