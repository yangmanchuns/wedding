# 모바일 청첩장 — 양병민 ❤ 김보원

2026. 12. 19. SAT PM 12:30 · 로얄파크

## 구성
- `index.html` — 청첩장 본체 (단일 파일, 정적)
- 사진 자리(hero / 갤러리 1~3 / 약도 / 안내 1~3)는 비워둠 → 나중에 이미지 추가

## 배포 (GitHub Pages)
1. GitHub에서 새 저장소 생성 (예: `wedding`)
2. 로컬에서 원격 연결 후 push
   ```
   git remote add origin https://github.com/<계정>/<저장소>.git
   git push -u origin main
   ```
3. 저장소 → Settings → Pages → Branch: `main` / `/ (root)` → Save
4. 잠시 후 `https://<계정>.github.io/<저장소>/` 로 접속

## 2차: Supabase 연동 (방명록 실시간 + RSVP + 하객 사진 업로드)
1. https://supabase.com 가입 → **New project** 생성 (Region: Northeast Asia (Seoul) 권장)
2. 왼쪽 **SQL Editor → New query** → `supabase_setup.sql` 전체 붙여넣고 **Run**
3. 왼쪽 **Settings → API** 에서 값 2개 복사:
   - **Project URL** → `index.html`의 `SUPABASE_URL`
   - **anon public** key → `index.html`의 `SUPABASE_ANON_KEY`
4. `index.html` 상단(스크립트 시작 부분)에 두 값 붙여넣기
5. commit & push → 새로고침하면 방명록·사진이 모두에게 실시간 공유됨

### 데이터 확인/추출 (커플용)
- **RSVP 명단**: Supabase → Table Editor → `rsvp_submissions` (또는 Export CSV)
- **하객 사진**: Supabase → Storage → `wedding-photos` 버킷에서 전체 다운로드

> anon key는 원래 공개용(브라우저에 넣는 값)이라 노출돼도 안전합니다. 데이터 보호는 RLS 정책이 담당합니다.
> `SUPABASE_URL`/`SUPABASE_ANON_KEY`가 비어 있으면 사이트는 자동으로 "브라우저 로컬 저장" 모드로 동작합니다(공유는 안 됨).
