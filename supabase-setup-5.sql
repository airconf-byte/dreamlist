-- ============================================================
-- 夢リスト100  追加SQL その5（みんなの夢ウォール）
-- SQL Editor に貼り付けて Run してください
-- ============================================================

-- 夢を個別で公開するフラグ
alter table public.dreams add column if not exists shared boolean default false;

-- みんなの公開された夢（夢＋名前だけ）を全員が読める関数
drop function if exists public.get_public_dreams();
create or replace function public.get_public_dreams()
returns table (text text, category text, done boolean, display_name text, created_at timestamptz)
language sql security definer set search_path = public as $$
  select d.text, d.category, d.done,
         coalesce(nullif(p.display_name, ''), '匿名の夢見人') as display_name,
         d.created_at
  from public.dreams d
  left join public.profiles p on p.id = d.user_id
  where d.shared = true
  order by d.created_at desc
  limit 300;
$$;
grant execute on function public.get_public_dreams() to anon, authenticated;

-- 完了！ 各夢の「🌐 公開」をONにすると、みんなの夢ウォールに名前つきで並びます。
