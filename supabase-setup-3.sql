-- ============================================================
-- 夢リスト100  追加SQL その3（写真ボード）
-- SQL Editor に貼り付けて Run してください
-- ============================================================

create table if not exists public.photos (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null default auth.uid() references auth.users(id) on delete cascade,
  data       text not null,          -- 圧縮した画像(データURL)
  rx         double precision default 0.5,   -- 配置用の乱数(0〜1)
  ry         double precision default 0.5,
  rot        double precision default 0,     -- 傾き(度)
  big        boolean default false,          -- 大きく表示する写真
  created_at timestamptz default now()
);

-- 既に photos を作成済みの場合の列追加
alter table public.photos add column if not exists big boolean default false;

alter table public.photos enable row level security;

drop policy if exists "own photos" on public.photos;
create policy "own photos" on public.photos
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- 完了！ 写真は本人だけが見られます（他人には公開されません）。
