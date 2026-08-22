-- ============================================================
-- 夢リスト100  追加SQL その4（BGMお気に入り共有）
-- SQL Editor に貼り付けて Run してください
-- ============================================================

create table if not exists public.bgm_tracks (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null default auth.uid() references auth.users(id) on delete cascade,
  title      text not null,
  youtube_id text not null,
  added_by   text,
  created_at timestamptz default now()
);

alter table public.bgm_tracks enable row level security;

-- 全員が一覧を読める（共有）／追加・削除は本人のみ
drop policy if exists "read bgm" on public.bgm_tracks;
create policy "read bgm" on public.bgm_tracks for select using (true);

drop policy if exists "insert own bgm" on public.bgm_tracks;
create policy "insert own bgm" on public.bgm_tracks for insert with check (auth.uid() = user_id);

drop policy if exists "delete own bgm" on public.bgm_tracks;
create policy "delete own bgm" on public.bgm_tracks for delete using (auth.uid() = user_id);

create index if not exists bgm_created_idx on public.bgm_tracks (created_at desc);

-- 完了！ 追加したYouTubeのBGMは全員の一覧に出て、みんなが再生できます。
