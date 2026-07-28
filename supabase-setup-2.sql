-- ============================================================
-- 夢リスト100  追加SQL その2（表示名・公開設定・ログ・ランキング）
-- Supabaseの SQL Editor に貼り付けて Run してください
-- ※ 先に supabase-setup.sql を実行済みであること
-- ============================================================

-- 1) プロフィールに「公開する」フラグを追加 ------------------
alter table public.profiles add column if not exists is_public boolean not null default false;

-- 2) 活動ログ（夢の追加・達成の履歴）------------------------
create table if not exists public.activity (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null default auth.uid() references auth.users(id) on delete cascade,
  kind       text not null,          -- 'add'（追加） | 'done'（達成）
  dream_text text,
  created_at timestamptz default now()
);
alter table public.activity enable row level security;

drop policy if exists "own activity" on public.activity;
create policy "own activity" on public.activity
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create index if not exists activity_created_idx on public.activity (created_at desc);

-- 3) ランキング（公開ユーザーのみ・達成数の多い順）----------
create or replace function public.get_leaderboard()
returns table (display_name text, done_count bigint, total_count bigint)
language sql security definer set search_path = public as $$
  select p.display_name,
         count(d.*) filter (where d.done) as done_count,
         count(d.*)                        as total_count
  from public.profiles p
  join public.dreams d on d.user_id = p.id
  where p.is_public = true and coalesce(p.display_name, '') <> ''
  group by p.id, p.display_name
  order by done_count desc, total_count desc
  limit 100;
$$;
grant execute on function public.get_leaderboard() to anon, authenticated;

-- 4) 活動フィード（公開ユーザーのみ・新着順）----------------
create or replace function public.get_activity_feed()
returns table (display_name text, kind text, dream_text text, created_at timestamptz)
language sql security definer set search_path = public as $$
  select p.display_name, a.kind, a.dream_text, a.created_at
  from public.activity a
  join public.profiles p on p.id = a.user_id
  where p.is_public = true and coalesce(p.display_name, '') <> ''
  order by a.created_at desc
  limit 50;
$$;
grant execute on function public.get_activity_feed() to anon, authenticated;

-- 完了！ 「公開」をONにしたユーザーだけがランキング・フィードに載ります。
