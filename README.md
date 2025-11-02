# 🔄 Cursor 설정 동기화

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Shell](https://img.shields.io/badge/Shell-Bash-green.svg)](https://www.gnu.org/software/bash/)
[![Platform](https://img.shields.io/badge/Platform-macOS-blue.svg)](https://www.apple.com/macos/)

여러 Mac에서 Cursor 설정을 iCloud로 동기화하는 스크립트 모음입니다.

## ✨ 주요 기능

- 🔗 **심볼릭 링크 기반 동기화** - 실시간 iCloud 동기화
- ⚙️ **유연한 설정** - 단일 배열로 모든 동기화 제어
- 🛡️ **안전한 백업** - 자동 백업 및 복원 기능
- 📦 **확장 프로그램 관리** - 일괄 백업 및 설치
- 🔍 **설정 검증** - 실행 전 미리 확인
- 📚 **자세한 문서** - 한글 가이드 및 예제

## 📦 설치

### iCloud Drive 내 아무 곳에나 클론

```bash
# iCloud Drive의 원하는 위치에 클론
cd "/Users/$USER/Library/Mobile Documents/com~apple~CloudDocs/Shared"
git clone git@github.com:potados99/cursor-sync.git cursor-sync
cd cursor-sync
```

또는 원하는 다른 경로:

```bash
# 예시: Documents 폴더
cd "/Users/$USER/Library/Mobile Documents/com~apple~CloudDocs/Documents"
git clone git@github.com:potados99/cursor-sync.git cursor-sync
cd cursor-sync
```

> 💡 **중요:** 동기화된 설정 파일(`CursorSettings/`)은 이 저장소 내부에 저장됩니다.  
> 저장소를 삭제하면 설정도 함께 날아가니 주의하세요!

---

## 📦 포함된 파일

### ⚙️ `sync-config.sh` - 동기화 설정 (중요!)
동기화할 항목을 설정하는 파일입니다. **이 파일을 수정하여 커스터마이징하세요!**

```bash
vim sync-config.sh
# 또는
nano sync-config.sh
```

**설정 방법:**
```bash
SYNC_PATHS=(
    "settings.json"          # 포함
    "keybindings.json"
    "snippets"
    "globalStorage"          # 전체 포함
    "!globalStorage/state.vscdb"     # 일부 제외 (!)
    "!globalStorage/storage.json"
)
```

**규칙:**
- User 폴더 기준 상대 경로
- `!`로 시작하면 제외
- 상위 경로가 있으면 하위 자동 포함
- 제외 항목이 있으면 재귀적으로 개별 링크

📚 자세한 설정 방법은 `CONFIG-GUIDE.md`를 참고하세요!

---

### 🌟 `setup-new-mac.sh` - 통합 셋업 (신규 Mac용)
새 Mac에서 모든 것을 한 번에 설정합니다. **가장 먼저 실행하세요!**

```bash
bash setup-new-mac.sh
```

**기능:**
- ✅ 설정 동기화 (`setup-sync.sh` 자동 실행)
- ✅ 확장 프로그램 설치 (가장 최신 install 스크립트 자동 실행)
- ✅ 진행 상황 표시 및 완료 안내

---

### 1. `export-to-icloud.sh` - 초기 백업
현재 Mac의 Cursor 설정을 iCloud로 백업합니다. **첫 번째 Mac에서 한 번만 실행**하세요.

```bash
bash export-to-icloud.sh
```

**백업 항목:**
- ✅ `settings.json` - 에디터 설정
- ✅ `keybindings.json` - 키보드 단축키
- ✅ `snippets/` - 코드 스니펫
- ✅ `globalStorage/` - 확장 프로그램 설정 (일부 제외)
  - ⏭️ `state.vscdb`, `state.vscdb.backup`, `storage.json`은 로컬 전용

---

### 2. `setup-sync.sh` - 동기화 설정
iCloud 설정을 현재 Mac과 심볼릭 링크로 연결합니다. **새로운 Mac에서 실행**하세요.

```bash
bash setup-sync.sh
```

**동작:**
1. 기존 링크가 있는지 확인 (있으면 중단)
2. 기존 `User` 폴더를 `User.local.YYYYMMDD-HHMMSS`로 백업
3. iCloud 설정과 심볼릭 링크 생성
4. `globalStorage`는 선택적으로 링크 (로컬 전용 파일 제외)

---

### 3. `unlink-sync.sh` - 동기화 해제
심볼릭 링크를 제거하고 실제 파일로 복원합니다.

```bash
bash unlink-sync.sh
```

**주의:** iCloud의 파일은 그대로 유지됩니다.

---

### 4. `export-extensions.sh` - 확장 프로그램 백업
현재 설치된 확장 프로그램 목록을 백업하고 설치 스크립트를 생성합니다.

```bash
bash export-extensions.sh
```

**생성 파일:** `install-extensions-YYYY-MM-DD-HHMMSS.sh`

---

### 5. `install-extensions-*.sh` - 확장 프로그램 설치
백업된 확장 프로그램을 일괄 설치합니다.

```bash
bash install-extensions-2025-11-02-114809.sh
```

---

## 🚀 새 Mac 셋업 가이드

### 방법 1: 자동 셋업 (추천) 🌟

**첫 번째 Mac에서 저장소가 이미 있다면, 새 Mac에서:**

```bash
# 1. 저장소로 이동 (iCloud 동기화 완료 대기 후)
cd "/Users/$USER/Library/Mobile Documents/com~apple~CloudDocs/Shared/cursor-sync"

# 2. 자동 셋업 실행
bash setup-new-mac.sh
```

**처음 시작하는 경우:**

```bash
# 1. iCloud Drive에 클론
cd "/Users/$USER/Library/Mobile Documents/com~apple~CloudDocs/Shared"
git clone git@github.com:potados99/cursor-sync.git cursor-sync
cd cursor-sync

# 2. 자동 셋업 실행
bash setup-new-mac.sh
```

이 스크립트가 자동으로:
- ✅ Cursor 설정 동기화
- ✅ 확장 프로그램 설치
- ✅ 완료 메시지 표시

---

### 방법 2: 수동 셋업

#### Step 1: iCloud 동기화 확인
iCloud Drive에 설정이 동기화되었는지 확인합니다.

```bash
# 클론한 디렉토리로 이동 (경로는 클론 위치에 따라 다를 수 있음)
cd "/Users/$USER/Library/Mobile Documents/com~apple~CloudDocs/Shared/cursor-sync"
ls CursorSettings
```

#### Step 2: Cursor 설정 동기화
```bash
bash setup-sync.sh
```

#### Step 3: 확장 프로그램 설치
```bash
# 가장 최신 install 스크립트 찾기
ls -t install-extensions-*.sh | head -1

# 설치 실행
bash install-extensions-YYYY-MM-DD-HHMMSS.sh
```

#### Step 4: Cursor 재시작
Cursor를 재시작하면 모든 설정이 적용됩니다! ✨

---

## 📋 일상적인 사용

### 확장 프로그램 백업 업데이트
새로운 확장을 설치했다면 정기적으로 백업하세요:

```bash
cd "/Users/$USER/Library/Mobile Documents/com~apple~CloudDocs/Shared/Cursor"
bash export-extensions.sh
```

### 설정 백업 업데이트
심볼릭 링크를 사용 중이므로 **자동으로 동기화**됩니다! 별도 작업 불필요합니다.

---

## ⚠️ 주의사항

### 1. 동시 사용
여러 Mac에서 동시에 Cursor를 사용하면 설정 충돌이 발생할 수 있습니다.
- 가능하면 한 번에 한 대의 Mac에서만 사용하세요
- iCloud 동기화가 완료될 때까지 기다린 후 다른 Mac에서 실행하세요

### 2. 백업
중요한 설정이 있다면 `export-to-icloud.sh`를 주기적으로 실행하여 백업하세요.

### 3. 로컬 전용 파일
다음 파일들은 동기화되지 않습니다 (로컬 캐시/상태):
- `globalStorage/state.vscdb`
- `globalStorage/state.vscdb.backup`
- `globalStorage/storage.json`
- `workspaceStorage/` - 워크스페이스별 설정
- `History/` - 파일 히스토리

---

## 🛠️ 문제 해결

### "이미 심볼릭 링크가 존재합니다" 오류
```bash
bash unlink-sync.sh  # 먼저 링크 해제
bash setup-sync.sh   # 다시 설정
```

### 설정이 동기화되지 않음
1. iCloud Drive 동기화 상태 확인
2. Finder에서 iCloud 폴더 확인
3. 네트워크 연결 확인

### 확장 프로그램이 설치되지 않음
```bash
# Cursor CLI 확인
which cursor

# 없다면 VS Code CLI 사용
which code

# PATH에 추가 필요시 (~/.zshrc 또는 ~/.bashrc)
export PATH="/Applications/Cursor.app/Contents/Resources/app/bin:$PATH"
```

---

## 📁 폴더 구조

```
~/Library/Mobile Documents/com~apple~CloudDocs/Shared/Cursor/
├── CursorSettings/              # 동기화되는 설정 (iCloud)
│   ├── keybindings.json
│   ├── settings.json
│   ├── snippets/
│   └── globalStorage/
│       ├── alefragnani.project-manager/
│       └── buenon.scratchpads/
├── export-to-icloud.sh         # 초기 백업 스크립트
├── setup-sync.sh               # 동기화 설정 스크립트
├── unlink-sync.sh              # 동기화 해제 스크립트
├── export-extensions.sh        # 확장 백업 스크립트
├── install-extensions-*.sh     # 확장 설치 스크립트 (생성됨)
└── README.md                   # 이 파일
```

---

## 💡 팁

### 빠른 명령어 설정
`~/.zshrc` 또는 `~/.bashrc`에 추가:

```bash
# Cursor 동기화 디렉토리로 빠르게 이동
alias cursor-sync='cd "/Users/$USER/Library/Mobile Documents/com~apple~CloudDocs/Shared/Cursor"'

# 확장 프로그램 백업
alias cursor-export='cd "/Users/$USER/Library/Mobile Documents/com~apple~CloudDocs/Shared/Cursor" && bash export-extensions.sh'
```

사용:
```bash
cursor-sync
cursor-export
```

---

## 🎉 완료!

이제 모든 Mac에서 동일한 Cursor 환경을 사용할 수 있습니다!

궁금한 점이 있다면 스크립트를 열어서 확인하거나 수정하세요.
모든 스크립트는 주석이 자세히 달려있습니다. 🚀

