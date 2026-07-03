# 모바일 청첩장 프로젝트 — 작업 가이드 (양병민 ♥ 김보원)

> 이 파일은 클로드 코드가 자동으로 읽는 프로젝트 컨텍스트입니다. 다른 PC에서 이 저장소를 클론해 이어서 작업할 때 이 문서를 기준으로 진행하세요.

## 1. 개요
- **무엇**: 양병민 ♥ 김보원 모바일 청첩장 (1인용 정적 웹사이트)
- **예식**: 2026. 12. 19.(토) 오후 12:30 · 로얄파크컨벤션(서울 용산구 이태원로 29, 전쟁기념관 내)
- **컨셉**: iOS **잠금화면 → (위로 스와이프) → 홈화면(앱 아이콘) → 각 앱 페이지** 구조
- **핵심 파일**: `index.html` 하나에 HTML+CSS+JS 전부 인라인 (프레임워크/빌드 없음)

## 2. 호스팅 & 배포
- **GitHub Pages**로 호스팅. 공개 URL: `https://yangmanchuns.github.io/wedding/`
- 이 폴더(`wedding-invitation`)가 곧 `wedding` 저장소의 루트. GitHub 계정: **yangmanchuns**
- 배포 = **커밋 후 push**. Pages 재배포 ~1분. 캐시 때문에 옛 버전 보이면 **시크릿창/하드 새로고침**.
- 커밋은 자유롭게, **push는 보통 사용자(양병민)가 직접** 한다.

## 3. 파일 구조
- `index.html` — 전체 사이트 (수정 대부분 여기)
- `manifest.webmanifest` — PWA(홈 화면 추가 시 전체화면)
- `supabase_setup.sql` — Supabase 테이블/정책/스토리지 생성 SQL
- `images/` — 사진 (main, gallery-01~19, venue-1~4, story-*, app-icon 등). 장당 200~470KB로 리사이즈됨. 전체 ~8MB.
- `music/bgm.mp3` — 배경음악
- `backup/` — 사용자 백업본(`index_pinter.html`, `index_origin.html` 등). git 추적 대상 아님.

## 4. 화면 구조 (index.html 내부)
- `#lock` 잠금화면: 배경 사진 + 시계(12:30) + 날짜 + "위로 쓸어올려 열기". 스와이프업/탭 → `unlock()`
- `#home` 홈: 배경 + **앱 아이콘 8개** + 하단 독(음악/카톡공유/링크복사)
- 앱 오버레이(각각 `.app`, 아래에서 위로 슬라이드, 우상단 ✕):
  - `app-story` 우리 이야기 (초대글·부모님·연락처·어린시절·달력·카운트다운·마무리) — **텍스트는 사용자가 다듬는 중**
  - `app-location` 오시는 길 (카카오맵·주소·교통·예식장 안내 카드)
  - `app-gallery` 갤러리 (메이슨리 2열, 잘림 없음, 전체표시, 라이트박스)
  - `app-rsvp` 참석 여부 (입력 폼 → `rsvp_submissions` insert)
  - `app-gift` 축의금 (계좌 아코디언)
  - `app-dress` 드레스 코드
  - `app-guestbook` 방명록 (Supabase 실시간)
  - `app-upload` 사진 올리기 (하객 업로드; **2026-12-19부터만** 가능하도록 날짜 게이트)
- **비밀 공간** `app-secret`: 홈 아이콘 없음. 홈의 `♥`를 **7번 클릭 → 비밀번호 → 탭2개(하객 사진 / 참석여부 데이터)**. 비번은 `checkSecret()` 참고.

## 5. 외부 서비스
- **Supabase** (DB+Storage+Realtime): URL/anon key는 `index.html` 상단 `SUPABASE_URL`/`SUPABASE_ANON_KEY`에 있음. anon key는 원래 공개용(보안은 RLS로).
  - 테이블: `guestbook_messages`, `rsvp_submissions`, `photos` / 스토리지 버킷 `wedding-photos`
  - 정책: 방명록 read+write, RSVP insert+select, photos read+write (전부 `using(true)` = anon 허용)
  - **새 환경/정책 변경 시 `supabase_setup.sql`을 Supabase → SQL Editor에서 실행**. (로컬 파일 수정만으론 실제 DB에 반영 안 됨!)
- **Kakao**: JS 키 `index.html`의 `KAKAO_JS_KEY`. 카카오 공유 + 지도(로얄파크컨벤션 좌표 37.5367693, 126.9755383 고정). Web 플랫폼 도메인에 `https://yangmanchuns.github.io` 등록돼 있어야 공유 작동.

## 6. 편집 규칙 (중요)
- **한글 인코딩**: `Edit` 도구로 한글 포함 라인을 수정하면 깨질 수 있음. **Node `fs`로 utf8 읽고/쓰는 패치 스크립트 방식**을 쓸 것.
  - 패턴: 스크래치패드에 `patch_*.js` 작성 → `fs.readFileSync(f,'utf8')` → `s.split(old).join(new)` → `fs.writeFileSync(f,s,'utf8')`.
- **JS 문법 검사**: 수정 후 `<script>` 블록만 뽑아 `node --check`로 확인 (regex `/<script>([\s\S]*)<\/script>\s*<\/body>/`).
- **인라인 onclick 문자열 안에서 `<script>` 전체 split 금지** (head의 src 스크립트까지 오염됨). 본문 마지막 스크립트만 노려서 `/<\/script>(\s*<\/body>)/` 사용.
- **커밋 메시지**: 무엇을 왜 바꿨는지 한국어로 구체적으로.
- 화면은 480px 프레임 중앙정렬, 색상: 아이보리+프레시그린(`--lime:#6f9f4f`), 폰트 Noto Sans KR + Gowun Batang.

## 7. 남은 작업(TODO) — 상황에 따라 갱신
- [ ] 우리 이야기(app-story) 텍스트·일상 사진 — 사용자가 정리해 전달 예정 (사진 주면 jimp으로 리사이즈 후 `images/`에)
- [ ] 신부 어린시절 실제 사진 + 부모님 손글씨 교체 (현재 임시)
- [ ] 신부측 연락처(김점식/신연정) 전화번호
- [ ] 계좌번호 다수 (신랑부/모, 신부·신부부/모)
- [ ] 전세버스 출발지/시간 확정 시 문구
- [ ] (보류) 비밀 기능 서버측 보호(RPC) — 지금은 비번이 클라이언트 소스에 노출됨

## 8. 참고
- 정적 사이트라 소스/이미지는 F12로 다 보임(숨김 불가). 진짜 보호가 필요하면 Supabase RPC로 서버측 검증 필요(현재 보류).
- 백업본은 `backup/`에. 마음에 안 들면 거기서 복원.
