# ⚙️ 동기화 설정 가이드

`sync-config.sh` 파일을 수정하여 동기화 대상을 자유롭게 설정할 수 있습니다.

## 📝 설정 파일 위치

```bash
sync-config.sh
```

## 🎯 설정 방법

### 기본 구조

```bash
SYNC_PATHS=(
    "settings.json"
    "keybindings.json"
    "snippets"
    "globalStorage"
    "!globalStorage/state.vscdb"
    "!globalStorage/state.vscdb.backup"
    "!globalStorage/storage.json"
)
```

### 📌 규칙

1. **경로는 `User` 폴더 기준 상대 경로**
   - `"settings.json"` = `~/Library/Application Support/Cursor/User/settings.json`
   - `"globalStorage/something"` = `~/Library/Application Support/Cursor/User/globalStorage/something`

2. **`!`로 시작하면 제외**
   - `"!globalStorage/state.vscdb"` = 해당 파일은 동기화 안함 (로컬에만 유지)

3. **상위 경로가 명시되면 하위는 자동 무시**
   - `"globalStorage"` 명시 + `"globalStorage/something"` 명시 = 후자는 무시됨

4. **제외가 있으면 재귀적으로 개별 링크**
   - `"globalStorage"` + `"!globalStorage/state.vscdb"` = globalStorage 내부를 순회하며 state.vscdb 제외하고 개별 링크

---

## 💡 예제

### 예제 1: 기본 설정 (추천)

```bash
SYNC_PATHS=(
    "settings.json"          # 설정 파일
    "keybindings.json"       # 키보드 단축키
    "snippets"               # 코드 스니펫
    "globalStorage"          # 확장 프로그램 데이터
    "!globalStorage/state.vscdb"           # DB 제외
    "!globalStorage/state.vscdb.backup"    # DB 백업 제외
    "!globalStorage/storage.json"          # 스토리지 제외
)
```

**결과:**
- `settings.json`, `keybindings.json` → 통째로 링크
- `snippets` 폴더 → 통째로 링크
- `globalStorage` → 내부를 순회하며 제외 3개 빼고 개별 링크

---

### 예제 2: 최소 동기화

```bash
SYNC_PATHS=(
    "settings.json"
    "keybindings.json"
)
```

**결과:**
- 설정 파일 2개만 동기화
- 나머지는 모두 로컬에만 유지

---

### 예제 3: globalStorage 완전 동기화

```bash
SYNC_PATHS=(
    "settings.json"
    "keybindings.json"
    "snippets"
    "globalStorage"      # 제외 없이 통째로
)
```

**결과:**
- globalStorage를 통째로 링크 (내부 DB 파일까지 모두 동기화)
- ⚠️ 주의: DB 파일 동기화는 문제를 일으킬 수 있음

---

### 예제 4: 특정 확장만 동기화

```bash
SYNC_PATHS=(
    "settings.json"
    "keybindings.json"
    "snippets"
    "globalStorage/alefragnani.project-manager"
    "globalStorage/buenon.scratchpads"
    "globalStorage/eamodio.gitlens"
)
```

**결과:**
- globalStorage 전체가 아닌 명시된 확장만 동기화
- 다른 확장 데이터는 로컬에만 유지

---

### 예제 5: 하위 경로 세밀 제어

```bash
SYNC_PATHS=(
    "settings.json"
    "keybindings.json"
    "globalStorage"
    "!globalStorage/state.vscdb"
    "!globalStorage/state.vscdb.backup"
    "!globalStorage/storage.json"
    "globalStorage/alefragnani.project-manager"      # 무시됨 (이미 globalStorage에 포함)
    "!globalStorage/some-extension.cache"            # 추가 제외
)
```

**결과:**
- globalStorage 내부를 순회
- 4개 항목 제외 (`state.vscdb`, `state.vscdb.backup`, `storage.json`, `some-extension.cache`)
- 나머지 모두 개별 링크

---

### 예제 6: 깊은 경로 제외

```bash
SYNC_PATHS=(
    "globalStorage"
    "!globalStorage/some-ext/cache"
    "!globalStorage/some-ext/temp"
    "!globalStorage/another-ext/logs"
)
```

**결과:**
- globalStorage 전체를 동기화하되
- some-ext/cache, some-ext/temp, another-ext/logs는 제외
- 해당 depth까지 재귀적으로 순회하며 제외 항목 스킵

---

## 🔍 동작 원리

### 1. 통째로 링크

```bash
SYNC_PATHS=(
    "snippets"
)
```

```
snippets → (iCloud의 snippets로 링크)
```

---

### 2. 재귀적 개별 링크 (제외 있음)

```bash
SYNC_PATHS=(
    "globalStorage"
    "!globalStorage/state.vscdb"
)
```

```
globalStorage/
├── state.vscdb              (로컬에만 유지)
├── project-manager → (iCloud로 링크)
├── scratchpads → (iCloud로 링크)
└── gitlens → (iCloud로 링크)
```

---

### 3. 깊은 제외

```bash
SYNC_PATHS=(
    "globalStorage"
    "!globalStorage/ext/cache"
)
```

```
globalStorage/
├── ext/
│   ├── cache               (로컬에만 유지)
│   ├── data → (iCloud로 링크)
│   └── config → (iCloud로 링크)
└── other-ext → (iCloud로 링크)
```

---

## ⚙️ 고급 설정

### workspaceStorage도 동기화하기

```bash
SYNC_PATHS=(
    "settings.json"
    "keybindings.json"
    "snippets"
    "globalStorage"
    "!globalStorage/state.vscdb"
    "!globalStorage/state.vscdb.backup"
    "!globalStorage/storage.json"
    "workspaceStorage"       # 추가
)
```

⚠️ **주의:** workspaceStorage는 프로젝트별 캐시로 크기가 클 수 있음

---

### 특정 JSON 파일들만

```bash
SYNC_PATHS=(
    "settings.json"
    "keybindings.json"
    "profiles.json"
)
```

---

### 일부 확장만 + 설정 파일

```bash
SYNC_PATHS=(
    "settings.json"
    "keybindings.json"
    "snippets"
    "globalStorage/alefragnani.project-manager"
    "globalStorage/buenon.scratchpads"
    # globalStorage 전체가 아닌 필요한 것만
)
```

---

## 🚫 동기화하면 안 되는 항목

절대 동기화하지 말아야 할 항목들:

```bash
# ❌ 절대 추가하지 마세요!
"CachedData"              # 캐시
"logs"                    # 로그
"globalStorage/state.vscdb"         # 상태 DB
"globalStorage/state.vscdb.backup"  # DB 백업
"globalStorage/storage.json"        # 스토리지 정보
```

이미 기본 설정에서 제외되어 있습니다.

---

## 📋 설정 변경 후 작업

### 1. 설정 파일 수정

```bash
cd "/Users/$USER/Library/Mobile Documents/com~apple~CloudDocs/Shared/Cursor"
vim sync-config.sh
```

### 2. 기존 동기화 해제 (이미 설정되어 있다면)

```bash
bash unlink-sync.sh
```

### 3. 새 설정으로 다시 동기화

```bash
bash setup-sync.sh
```

### 4. 설정 확인

스크립트 실행 시 다음과 같이 표시됩니다:

```
📋 동기화 설정:

  ✅ 포함 경로:
    • settings.json
    • keybindings.json
    • snippets
    • globalStorage (하위에 제외 항목 있음)

  ⊝ 제외 경로:
    • globalStorage/state.vscdb
    • globalStorage/state.vscdb.backup
    • globalStorage/storage.json
```

---

## 💡 팁

### 1. 어떤 파일이 있는지 확인

```bash
# User 폴더 확인
ls -la ~/Library/Application\ Support/Cursor/User/

# globalStorage 확인
ls -la ~/Library/Application\ Support/Cursor/User/globalStorage/
```

### 2. 점진적으로 추가

처음에는 최소한만 동기화하고 필요에 따라 추가:

```bash
# 시작
SYNC_PATHS=(
    "settings.json"
    "keybindings.json"
)

# → snippets 추가
SYNC_PATHS=(
    "settings.json"
    "keybindings.json"
    "snippets"
)

# → globalStorage 추가
SYNC_PATHS=(
    "settings.json"
    "keybindings.json"
    "snippets"
    "globalStorage"
    "!globalStorage/state.vscdb"
    "!globalStorage/state.vscdb.backup"
    "!globalStorage/storage.json"
)
```

### 3. 테스트 환경에서 먼저

중요한 데이터가 있다면 백업 후 테스트:

```bash
# 백업
cp -R ~/Library/Application\ Support/Cursor/User ~/Desktop/Cursor-User-backup

# 테스트
bash setup-sync.sh

# 문제 있으면 복원
rm -rf ~/Library/Application\ Support/Cursor/User
mv ~/Desktop/Cursor-User-backup ~/Library/Application\ Support/Cursor/User
```

---

## 🎓 정리

- **단순한 경로 배열 하나로 모든 것을 제어**
- **`!`로 제외 항목 명시**
- **상위 포함 + 하위 제외 = 재귀적 개별 링크**
- **제외 없으면 통째로 링크 (빠르고 간단)**

더 자세한 내용은 `README.md`를 참고하세요!
