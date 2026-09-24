-- ============================================================
-- 모바일 청첩장 Supabase 설정
-- 사용법: Supabase 프로젝트 → 왼쪽 SQL Editor → New query →
--         아래 전체 복사·붙여넣기 → Run
-- ============================================================

-- 1) 방명록 (누구나 읽기/쓰기)
create table if not exists public.guestbook_messages (
  id          uuid primary key default gen_random_uuid(),
  author      text not null,
  content     text not null,
  color_index int  not null default 0,
  created_at  timestamptz not null default now()
);

-- 2) 참석여부 RSVP (누구나 쓰기, 읽기는 커플만 = 대시보드)
create table if not exists public.rsvp_submissions (
  id              uuid primary key default gen_random_uuid(),
  name            text not null,
  phone           text,
  side            text,       -- 신랑측/신부측
  attendance      text,       -- 참석/불참석
  guest_count     int,
  guest           text,       -- 동행인
  meal_preference text,       -- 예정/안함/미정
  message         text,
  created_at      timestamptz not null default now()
);

-- 3) 하객 사진 메타 (파일은 Storage, 링크는 여기)
create table if not exists public.photos (
  id         uuid primary key default gen_random_uuid(),
  url        text not null,
  path       text not null,
  uploader   text,
  created_at timestamptz not null default now()
);

-- ---------- RLS 켜기 ----------
alter table public.guestbook_messages enable row level security;
alter table public.rsvp_submissions   enable row level security;
alter table public.photos             enable row level security;

-- ---------- 정책 ----------
-- 방명록: 누구나 읽기 + 쓰기
drop policy if exists "gb_select" on public.guestbook_messages;
drop policy if exists "gb_insert" on public.guestbook_messages;
create policy "gb_select" on public.guestbook_messages for select using (true);
create policy "gb_insert" on public.guestbook_messages for insert with check (true);

-- RSVP: 누구나 쓰기. 읽기는 anon 에게 열지 않는다(이름·전화번호가 들어있음).
--       비밀공간은 아래 get_rsvp(pw) 함수를 통해서만 읽는다.
drop policy if exists "rsvp_insert" on public.rsvp_submissions;
create policy "rsvp_insert" on public.rsvp_submissions for insert with check (true);
drop policy if exists "rsvp_select" on public.rsvp_submissions;   -- 직접 select 금지

-- 사진: 누구나 읽기 + 쓰기(메타)
drop policy if exists "photos_select" on public.photos;
drop policy if exists "photos_insert" on public.photos;
create policy "photos_select" on public.photos for select using (true);
create policy "photos_insert" on public.photos for insert with check (true);

-- ---------- 실시간(Realtime) ----------
alter publication supabase_realtime add table public.guestbook_messages;
alter publication supabase_realtime add table public.photos;

-- ---------- Storage 버킷 (사진 파일 저장소) ----------
insert into storage.buckets (id, name, public)
values ('wedding-photos', 'wedding-photos', true)
on conflict (id) do nothing;

-- 사진 버킷: 누구나 업로드 + 읽기
drop policy if exists "photo_upload" on storage.objects;
drop policy if exists "photo_read"   on storage.objects;
create policy "photo_upload" on storage.objects for insert to anon
  with check (bucket_id = 'wedding-photos');
create policy "photo_read" on storage.objects for select to anon
  using (bucket_id = 'wedding-photos');

-- 끝. 이제 Settings → API 에서 Project URL + anon key 를 복사해
-- index.html 상단 SUPABASE_URL / SUPABASE_ANON_KEY 에 넣으세요.

-- ============================================================
-- 비밀 공간 서버측 보호 (RPC)
--   비밀번호를 클라이언트에서 비교하지 않고 서버에서 해시로 검증한다.
--   index.html 의 checkSecret() / loadRsvp() 가 get_rsvp(pw) 를 호출한다.
--   ※ 아래 세 단계를 '따로따로' 실행할 것. 한 번에 붙여넣으면 SQL 에디터가
--     함수 본문의 세미콜론에서 문장을 잘라 syntax error 가 난다.
-- ============================================================

-- [1단계] pgcrypto + 비번 해시 보관함
--   Supabase 에서 pgcrypto 는 public 이 아니라 extensions 스키마에 깔린다.
create extension if not exists pgcrypto with schema extensions;

create table if not exists private_config (k text primary key, v text);
alter table private_config enable row level security;   -- 정책 없음 = anon 은 못 읽음

-- ★★ 아래 '여기에_원하는_비밀번호' 를 반드시 실제 비번으로 바꾸고 Run 할 것.
--    (예시 문자열 그대로 실행하면 그게 진짜 비번이 되어버린다. 실제로 한 번 그랬음)
insert into private_config (k, v)
values ('secret_pw', extensions.crypt('여기에_원하는_비밀번호', extensions.gen_salt('bf')))
on conflict (k) do update set v = excluded.v;

-- 나중에 비번만 바꾸고 싶을 때:
--   update private_config
--   set v = extensions.crypt('새비번', extensions.gen_salt('bf'))
--   where k = 'secret_pw';
-- 확인:
--   select extensions.crypt('새비번', v) = v as ok from private_config where k='secret_pw';

-- [2단계] 검증 함수 (이 블록만 따로 Run)
create or replace function get_rsvp(pw text)
returns setof rsvp_submissions
language plpgsql
security definer                          -- 소유자 권한으로 실행 → RLS 우회
set search_path = public, extensions
as $fn$
begin
  if not exists (
    select 1 from private_config
    where k = 'secret_pw' and v = extensions.crypt(pw, v)
  ) then
    raise exception 'unauthorized';
  end if;
  return query select * from rsvp_submissions order by created_at desc;
end;
$fn$;

-- [3단계] 실행 권한
revoke all on function get_rsvp(text) from public;
grant execute on function get_rsvp(text) to anon;

-- 확인용
--   select count(*) from get_rsvp('맞는비번');   -- 숫자가 나오면 성공
--   select count(*) from get_rsvp('틀린비번');   -- unauthorized 에러가 나야 정상
