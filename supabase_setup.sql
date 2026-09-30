-- =====================================================================
-- スイカン面接評価アプリ 用 Supabase セットアップスクリプト
-- Supabaseダッシュボード → SQL Editor → New query に貼り付けて実行してください。
-- 実行前に、下の方にある「YOUR_PASSPHRASE_HERE」を、結果一覧を見るための
-- 好きなパスフレーズ（合言葉）に書き換えてから実行してください。
-- =====================================================================

-- パスワードハッシュ化のための拡張機能を有効化
create extension if not exists pgcrypto;

-- 評価データを保存するテーブル
create table if not exists evaluations (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz default now(),

  candidate_name text not null,
  interview_date date not null,
  interviewer_name text not null,

  q1 text, q2 text, q3 text, q4 text, q5 text,
  q6 text, q7 text, q8 text, q9 text, q10 text,

  crit1 int, crit2 int, crit3 int, crit4 int,
  crit5 int, crit6 int, crit7 int, crit8 int,

  disc_d1 int, disc_d2 int, disc_d3 int,
  disc_i1 int, disc_i2 int, disc_i3 int,
  disc_s1 int, disc_s2 int, disc_s3 int,
  disc_c1 int, disc_c2 int, disc_c3 int,

  weighted_total numeric,
  score_pct numeric,
  min_score int,
  judge text,

  disc_d_total int, disc_i_total int, disc_s_total int, disc_c_total int,
  disc_type text,
  disc_profile text
);

-- 行レベルセキュリティ（RLS）を有効化
alter table evaluations enable row level security;

-- 誰でも（ログイン不要で）新しい評価を「追加」できるようにする
-- ※ただしこのポリシーだけでは「閲覧」はできません（下のRPC関数経由のみ）
drop policy if exists "anon can insert evaluations" on evaluations;
create policy "anon can insert evaluations" on evaluations
  for insert
  to anon
  with check (true);

-- RLSポリシーだけでなく、テーブルへの「追加」権限そのものもanonロールに付与する必要があります
grant usage on schema public to anon;
grant insert on evaluations to anon;

-- 閲覧用パスフレーズを保管する小さなテーブル（ハッシュ化して保存）
create table if not exists app_secrets (
  key text primary key,
  value text
);
alter table app_secrets enable row level security;
-- app_secrets はクライアントから直接アクセスさせない（ポリシーを作らない = 全拒否）

-- ここでパスフレーズを設定します。「YOUR_PASSPHRASE_HERE」を書き換えてください。
insert into app_secrets (key, value)
values ('admin_passphrase_hash', crypt('YOUR_PASSPHRASE_HERE', gen_salt('bf')))
on conflict (key) do update set value = excluded.value;

-- 結果一覧を取得するための関数。正しいパスフレーズを渡したときだけデータを返す
create or replace function get_results(pw text)
returns setof evaluations
language plpgsql
security definer
set search_path = public, extensions
as $$
begin
  if exists (
    select 1 from app_secrets
    where key = 'admin_passphrase_hash' and value = crypt(pw, value)
  ) then
    return query select * from evaluations order by created_at desc;
  else
    return;
  end if;
end;
$$;

-- ログイン不要のユーザー（anon）がこの関数を呼べるようにする
grant execute on function get_results(text) to anon;
