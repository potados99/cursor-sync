#!/bin/bash

# Cursor 동기화 설정 파일
# 모든 동기화 스크립트에서 공통으로 사용하는 설정과 함수들

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 경로 설정
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# 이 스크립트가 위치한 디렉토리를 기준으로 iCloud 경로 계산
# 어디에 클론하든 자동으로 경로 설정됨
SCRIPT_DIR_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ICLOUD_DIR="$SCRIPT_DIR_PATH/CursorSettings"
LOCAL_USER_DIR="$HOME/Library/Application Support/Cursor/User"
BACKUP_DIR="$HOME/Library/Application Support/Cursor/User.backups"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 동기화 대상 설정
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# User 폴더 기준 상대 경로
# - 경로는 파일 또는 디렉토리
# - ! 로 시작하면 제외 (오버라이드)
# - 상위 경로가 명시되면 하위 경로는 자동 무시
# - 제외(!)가 있으면 해당 depth까지 재귀적으로 개별 링크

SYNC_PATHS=(
    "settings.json"
    "keybindings.json"
    "snippets"
    "globalStorage"
    "!globalStorage/state.vscdb"
    "!globalStorage/state.vscdb.backup"
    "!globalStorage/storage.json"
)

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 색상 정의
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 경로 처리 함수
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# 경로가 다른 경로의 하위인지 확인
# is_subpath "globalStorage/state.vscdb" "globalStorage" -> true
is_subpath() {
    local path="$1"
    local parent="$2"
    
    # 정확히 같으면 하위가 아님
    if [ "$path" = "$parent" ]; then
        return 1
    fi
    
    # parent로 시작하고 그 다음이 /이면 하위
    if [[ "$path" == "$parent/"* ]]; then
        return 0
    fi
    
    return 1
}

# 포함/제외 경로 분리 및 정리
parse_sync_paths() {
    local include_paths=()
    local exclude_paths=()
    
    for path in "${SYNC_PATHS[@]}"; do
        if [[ "$path" == "!"* ]]; then
            # 제외 경로 (! 제거)
            exclude_paths+=("${path:1}")
        else
            # 포함 경로
            include_paths+=("$path")
        fi
    done
    
    # 포함 경로 중복 제거 (상위 경로가 있으면 하위 제거)
    local filtered_include=()
    for path in "${include_paths[@]}"; do
        local is_redundant=false
        for other in "${include_paths[@]}"; do
            if [ "$path" != "$other" ] && is_subpath "$path" "$other"; then
                is_redundant=true
                break
            fi
        done
        if [ "$is_redundant" = false ]; then
            filtered_include+=("$path")
        fi
    done
    
    # 결과를 전역 변수로 반환
    PARSED_INCLUDE_PATHS=("${filtered_include[@]}")
    PARSED_EXCLUDE_PATHS=("${exclude_paths[@]}")
}

# 특정 경로가 제외 대상인지 확인
is_excluded() {
    local path="$1"
    
    for exclude in "${PARSED_EXCLUDE_PATHS[@]}"; do
        if [ "$path" = "$exclude" ]; then
            return 0
        fi
    done
    return 1
}

# 특정 경로 아래에 제외 항목이 있는지 확인
has_exclusions_under() {
    local parent="$1"
    
    for exclude in "${PARSED_EXCLUDE_PATHS[@]}"; do
        if is_subpath "$exclude" "$parent"; then
            return 0
        fi
    done
    return 1
}

# 경로를 재귀적으로 링크 (제외 항목 고려)
# recursive_link_path "globalStorage" 0
recursive_link_path() {
    local rel_path="$1"
    local depth="$2"
    local source="$LOCAL_USER_DIR/$rel_path"
    local target="$ICLOUD_DIR/$rel_path"
    
    # 제외 대상이면 스킵
    if is_excluded "$rel_path"; then
        return
    fi
    
    # 하위에 제외 항목이 없으면 통째로 링크
    if ! has_exclusions_under "$rel_path"; then
        link_item "$rel_path"
        return
    fi
    
    # 하위에 제외 항목이 있으면 재귀적으로 처리
    if [ ! -d "$source" ] && [ ! -d "$target" ]; then
        # 디렉토리가 아니면 링크
        link_item "$rel_path"
        return
    fi
    
    # 디렉토리면 내부 순회
    local base_dir="$source"
    if [ ! -d "$source" ] && [ -d "$target" ]; then
        base_dir="$target"
    fi
    
    if [ ! -d "$base_dir" ]; then
        return
    fi
    
    # 내부 항목들 처리
    for item in "$base_dir"/*; do
        if [ ! -e "$item" ]; then
            continue
        fi
        
        local item_name=$(basename "$item")
        local item_rel_path="$rel_path/$item_name"
        
        if is_excluded "$item_rel_path"; then
            echo "   ⏭️  제외: $item_rel_path"
            continue
        fi
        
        # 재귀 호출
        recursive_link_path "$item_rel_path" $((depth + 1))
    done
}

# 실제 링크 작업 수행
link_item() {
    local rel_path="$1"
    local source="$LOCAL_USER_DIR/$rel_path"
    local target="$ICLOUD_DIR/$rel_path"
    local timestamp=$(get_timestamp)
    local backup="$BACKUP_DIR/$rel_path.$timestamp"
    
    # 이미 링크되어 있으면 스킵
    if [ -L "$source" ]; then
        return
    fi
    
    # 백업 디렉토리 생성
    local backup_dir=$(dirname "$backup")
    mkdir -p "$backup_dir"
    
    # 로컬에 있으면 백업
    if [ -e "$source" ]; then
        echo "   💾 백업: $rel_path"
        if [ -d "$source" ]; then
            cp -R "$source" "$backup"
        else
            cp "$source" "$backup"
        fi
        
        # iCloud에 없으면 복사
        if [ ! -e "$target" ]; then
            echo "   📤 iCloud로 복사: $rel_path"
            local target_dir=$(dirname "$target")
            mkdir -p "$target_dir"
            if [ -d "$source" ]; then
                cp -R "$source" "$target"
            else
                cp "$source" "$target"
            fi
        fi
        
        # 원본 제거
        rm -rf "$source"
    else
        # 로컬에 없으면 iCloud 확인
        if [ ! -e "$target" ]; then
            # 둘 다 없으면 생성
            local target_dir=$(dirname "$target")
            mkdir -p "$target_dir"
            
            if [[ "$rel_path" == *.json ]]; then
                echo "   📝 생성: $rel_path (빈 JSON)"
                echo "{}" > "$target"
            else
                echo "   📁 생성: $rel_path (빈 폴더)"
                mkdir -p "$target"
            fi
        fi
    fi
    
    # 심볼릭 링크 생성
    local source_dir=$(dirname "$source")
    mkdir -p "$source_dir"
    echo "   🔗 링크 생성: $rel_path"
    ln -s "$target" "$source"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 유틸리티 함수
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# 타임스탬프 생성
get_timestamp() {
    date +"%Y%m%d-%H%M%S"
}

# 백업 폴더 생성
ensure_backup_dir() {
    mkdir -p "$BACKUP_DIR"
}

# iCloud 폴더 생성
ensure_icloud_dir() {
    mkdir -p "$ICLOUD_DIR"
}

# 로컬 User 폴더 생성
ensure_local_dir() {
    mkdir -p "$LOCAL_USER_DIR"
}

# 경로 유효성 검사
validate_paths() {
    if [ ! -d "$ICLOUD_DIR" ]; then
        echo -e "${RED}❌ 오류: iCloud 설정 폴더를 찾을 수 없습니다${NC}" >&2
        echo "   경로: $ICLOUD_DIR" >&2
        echo "" >&2
        echo "💡 먼저 다른 Mac에서 설정을 iCloud에 백업하세요." >&2
        return 1
    fi
    return 0
}

# 설정 정보 출력
print_sync_config() {
    echo -e "${BLUE}📋 동기화 설정:${NC}"
    echo ""
    
    # 경로 파싱
    parse_sync_paths
    
    echo "  ✅ 포함 경로:"
    for path in "${PARSED_INCLUDE_PATHS[@]}"; do
        if has_exclusions_under "$path"; then
            echo "    • $path ${YELLOW}(하위에 제외 항목 있음)${NC}"
        else
            echo "    • $path"
        fi
    done
    
    if [ ${#PARSED_EXCLUDE_PATHS[@]} -gt 0 ]; then
        echo ""
        echo "  ⊝ 제외 경로:"
        for path in "${PARSED_EXCLUDE_PATHS[@]}"; do
            echo "    • $path"
        done
    fi
    echo ""
}

# 설정이 로드되었음을 표시
SYNC_CONFIG_LOADED=1
