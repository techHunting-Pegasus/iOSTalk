-- Relationship and privacy migration for iOStalk.
-- Run this in Supabase SQL editor.

begin;

-- 1) User privacy flag used by follow-request logic.
alter table if exists public."Users"
  add column if not exists is_private_account boolean not null default false;

-- 2) Extend user_followers table to support full follow/friend workflow.
alter table if exists public.user_followers
  add column if not exists friend_requested_by text,
  add column if not exists created_at timestamptz not null default now(),
  add column if not exists updated_at timestamptz not null default now();

-- Normalize legacy status values.
update public.user_followers
set status = case
  when status = 'pending' then 'follow_pending'
  when status = 'accepted' then 'follower'
  else status
end
where status in ('pending', 'accepted');

-- Ensure supported statuses only.
alter table if exists public.user_followers
  drop constraint if exists user_followers_status_check;

alter table if exists public.user_followers
  add constraint user_followers_status_check
  check (status in ('follow_pending', 'follower', 'friend_pending', 'friend'));

-- Enforce one directed relationship row per follower -> following pair.
create unique index if not exists user_followers_unique_pair_idx
  on public.user_followers (follower_id, following_id);

-- Helpful indexes for request and relation lookups.
create index if not exists user_followers_following_status_idx
  on public.user_followers (following_id, status);

create index if not exists user_followers_follower_status_idx
  on public.user_followers (follower_id, status);

-- Keep updated_at current.
create or replace function public.set_updated_at_timestamp()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_user_followers_updated_at on public.user_followers;

create trigger set_user_followers_updated_at
before update on public.user_followers
for each row
execute function public.set_updated_at_timestamp();

commit;
