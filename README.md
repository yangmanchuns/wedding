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

## 다음 단계 (2차)
- 방명록/RSVP 공유 + 결혼사진 업로드 → Supabase(DB + Storage) 연동 예정
