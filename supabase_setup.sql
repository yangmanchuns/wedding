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

-- RSVP: 누구나 쓰기 (개인정보라 읽기는 정책 없음 → 커플은 대시보드에서 확인)
drop policy if exists "rsvp_insert" on public.rsvp_submissions;
create policy "rsvp_insert" on public.rsvp_submissions for insert with check (true);
drop policy if exists "rsvp_select" on public.rsvp_submissions;
create policy "rsvp_select" on public.rsvp_submissions for select using (true);

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
