# 🚀 Cursor 동기화 빠른 시작 가이드

## 📦 설치

```bash
# iCloud Drive의 원하는 위치에 클론
cd "/Users/$USER/Library/Mobile Documents/com~apple~CloudDocs/Shared"
git clone git@github.com:potados99/cursor-sync.git Cursor
cd Cursor
```

> ⚠️ **중요:** 설정 파일은 이 저장소 내부(`CursorSettings/`)에 저장됩니다!

---

## ⚙️ 설정 커스터마이징 (선택사항)

동기화할 항목을 변경하고 싶다면:

```bash
cd "/Users/$USER/Library/Mobile Documents/com~apple~CloudDocs/Shared/Cursor"
vim sync-config.sh
```

📚 자세한 내용: `CONFIG-GUIDE.md`

---

## 첫 번째 Mac (현재 Mac)

### 1️⃣ 확장 프로그램 백업
```bash
cd "/Users/$USER/Library/Mobile Documents/com~apple~CloudDocs/Shared/Cursor"
bash export-extensions.sh
```

### 2️⃣ 설정 iCloud로 백업 (선택사항)
이미 `CursorSettings` 폴더가 있다면 건너뛰세요.

```bash
bash export-to-icloud.sh
```

### ✅ 완료!
iCloud 동기화가 끝날 때까지 기다리세요.

---

## 새로운 Mac

### 🎯 한 줄로 완료
```bash
cd "/Users/$USER/Library/Mobile Documents/com~apple~CloudDocs/Shared/Cursor"
bash setup-new-mac.sh
```

### ✅ 완료!
Cursor를 실행하면 모든 설정이 적용되어 있습니다!

---

## 일상적인 사용

### 확장 프로그램이 바뀌었을 때
```bash
cd "/Users/$USER/Library/Mobile Documents/com~apple~CloudDocs/Shared/Cursor"
bash export-extensions.sh
```

### 동기화 해제하고 싶을 때
```bash
cd "/Users/$USER/Library/Mobile Documents/com~apple~CloudDocs/Shared/Cursor"
bash unlink-sync.sh
```

---

## 💡 빠른 접근 (선택사항)

`~/.zshrc`에 추가:

```bash
alias cs='cd "/Users/$USER/Library/Mobile Documents/com~apple~CloudDocs/Shared/Cursor"'
alias cursor-backup='cs && bash export-extensions.sh'
```

사용:
```bash
cs              # Cursor 동기화 폴더로 이동
cursor-backup   # 확장 프로그램 백업
```

---

더 자세한 내용은 `README.md`를 참고하세요!



