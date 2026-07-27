-- ============================================================
-- 夢リスト100  Supabaseセットアップ用SQL
-- Supabase管理画面の「SQL Editor」に全部貼り付けて Run するだけ
-- ============================================================

-- 1) 夢テーブル ------------------------------------------------
create table if not exists public.dreams (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null default auth.uid() references auth.users(id) on delete cascade,
  text       text not null,
  category   text not null default 'work',
  deadline   text default 'いつか',
  why        text default '',
  done       boolean not null default false,
  done_date  text,
  sort       double precision default 0,
  created_at timestamptz default now()
);

alter table public.dreams enable row level security;

drop policy if exists "own dreams" on public.dreams;
create policy "own dreams" on public.dreams
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- 2) プロフィール（共有用の名前とトークン）--------------------
create table if not exists public.profiles (
  id           uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  share_token  uuid not null default gen_random_uuid(),
  is_shared    boolean not null default false,
  created_at   timestamptz default now()
);

alter table public.profiles enable row level security;

drop policy if exists "own profile" on public.profiles;
create policy "own profile" on public.profiles
  for all
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- 3) 新規ユーザー登録時に profiles を自動作成 ------------------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id) values (new.id) on conflict do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- 4) 共有リンク用の読み取り専用関数（トークンで他人が閲覧）----
create or replace function public.get_shared_list(token uuid)
returns table (
  text text, category text, deadline text, why text,
  done boolean, done_date text, sort double precision, owner_name text
)
language sql
security definer set search_path = public
as $$
  select d.text, d.category, d.deadline, d.why, d.done, d.done_date, d.sort, p.display_name
  from public.profiles p
  join public.dreams d on d.user_id = p.id
  where p.share_token = token and p.is_shared = true
  order by d.sort;
$$;

grant execute on function public.get_shared_list(uuid) to anon, authenticated;

-- 完了！ このあと index.html の SUPABASE_URL / SUPABASE_ANON_KEY を設定してください。
