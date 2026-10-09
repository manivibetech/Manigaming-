-- MANIGAMING Supabase database setup. Run all of this in Supabase > SQL Editor.
create extension if not exists pgcrypto;
create table if not exists public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 gamer_name text not null default 'Player' check(char_length(gamer_name) between 1 and 24),
 favorite_game text not null default 'PUBG Mobile' check(favorite_game in ('PUBG Mobile','Free Fire','Other')),
 role text not null default 'player' check(role in ('player','admin')),
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.tournaments (
 id uuid primary key default gen_random_uuid(), title text not null check(char_length(title) between 2 and 80),
 game text not null check(game in ('PUBG Mobile','Free Fire')), starts_at timestamptz not null,
 max_players integer not null default 100 check(max_players between 2 and 500),
 description text not null default '' check(char_length(description)<=500),
 status text not null default 'open' check(status in ('open','closed','completed','cancelled')),
 created_by uuid references auth.users(id) on delete set null, created_at timestamptz not null default now()
);
create table if not exists public.registrations (
 id uuid primary key default gen_random_uuid(), tournament_id uuid not null references public.tournaments(id) on delete cascade,
 user_id uuid not null references auth.users(id) on delete cascade, created_at timestamptz not null default now(),
 unique(tournament_id,user_id)
);
create table if not exists public.scores (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
 game text not null check(game in ('PUBG Mobile','Free Fire')), points integer not null default 0 check(points between 0 and 10000000),
 created_at timestamptz not null default now()
);
create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path='' as $$
begin
 insert into public.profiles(id,gamer_name,favorite_game,role)
 values(new.id,coalesce(nullif(left(new.raw_user_meta_data->>'gamer_name',24),''),split_part(new.email,'@',1),'Player'),'PUBG Mobile','player')
 on conflict(id) do nothing; return new;
end; $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.handle_new_user();
create or replace function public.is_admin() returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.profiles p where p.id=(select auth.uid()) and p.role='admin');
$$;
alter table public.profiles enable row level security;
alter table public.tournaments enable row level security;
alter table public.registrations enable row level security;
alter table public.scores enable row level security;
drop policy if exists "Profiles readable" on public.profiles;
create policy "Profiles readable" on public.profiles for select to anon,authenticated using(true);
drop policy if exists "Users update own profile fields" on public.profiles;
create policy "Users update own profile fields" on public.profiles for update to authenticated using(id=(select auth.uid())) with check(id=(select auth.uid()));
drop policy if exists "Open tournaments visible" on public.tournaments;
create policy "Open tournaments visible" on public.tournaments for select to anon,authenticated using(status='open' or public.is_admin());
drop policy if exists "Admins create tournaments" on public.tournaments;
create policy "Admins create tournaments" on public.tournaments for insert to authenticated with check(public.is_admin());
drop policy if exists "Admins update tournaments" on public.tournaments;
create policy "Admins update tournaments" on public.tournaments for update to authenticated using(public.is_admin()) with check(public.is_admin());
drop policy if exists "Admins delete tournaments" on public.tournaments;
create policy "Admins delete tournaments" on public.tournaments for delete to authenticated using(public.is_admin());
drop policy if exists "Users view own registrations or admin" on public.registrations;
create policy "Users view own registrations or admin" on public.registrations for select to authenticated using(user_id=(select auth.uid()) or public.is_admin());
drop policy if exists "Users register themselves" on public.registrations;
create policy "Users register themselves" on public.registrations for insert to authenticated with check(user_id=(select auth.uid()) and exists(select 1 from public.tournaments t where t.id=tournament_id and t.status='open'));
drop policy if exists "Admins delete registrations" on public.registrations;
create policy "Admins delete registrations" on public.registrations for delete to authenticated using(public.is_admin());
drop policy if exists "Scores visible" on public.scores;
create policy "Scores visible" on public.scores for select to anon,authenticated using(true);
drop policy if exists "Admins add scores" on public.scores;
create policy "Admins add scores" on public.scores for insert to authenticated with check(public.is_admin());
drop policy if exists "Admins update scores" on public.scores;
create policy "Admins update scores" on public.scores for update to authenticated using(public.is_admin()) with check(public.is_admin());
drop policy if exists "Admins delete scores" on public.scores;
create policy "Admins delete scores" on public.scores for delete to authenticated using(public.is_admin());
create or replace view public.leaderboard with (security_invoker=true) as
 select p.gamer_name,s.game,s.points,s.created_at from public.scores s join public.profiles p on p.id=s.user_id;
grant select on public.leaderboard to anon,authenticated;
grant select on public.profiles to anon,authenticated;
grant update(gamer_name,favorite_game,updated_at) on public.profiles to authenticated;
grant select on public.tournaments to anon,authenticated;
grant insert,update,delete on public.tournaments to authenticated;
grant select,insert,delete on public.registrations to authenticated;
grant select,insert,update,delete on public.scores to authenticated;
-- After signing up, replace YOUR_EMAIL_HERE with your email and run this separately to become admin:
-- update public.profiles p set role='admin' where p.id=(select u.id from auth.users u where lower(u.email)=lower('YOUR_EMAIL_HERE'));
