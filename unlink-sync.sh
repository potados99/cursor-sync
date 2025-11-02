#!/bin/bash

# Cursor 설정 iCloud 동기화 해제 스크립트
# 심볼릭 링크를 제거하고 실제 파일로 복원합니다

set -e

# 설정 파일 로드
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/sync-config.sh"

# 인자 파싱
BROKEN_ONLY=false
if [ "$1" = "--broken" ]; then
    BROKEN_ONLY=true
fi

if [ "$BROKEN_ONLY" = true ]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔧 부서진 링크 제거"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
else
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔓 Cursor 설정 iCloud 동기화 해제"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
fi

# User 디렉토리 존재 확인
if [ ! -d "$LOCAL_USER_DIR" ]; then
    echo -e "${RED}❌ User 디렉토리를 찾을 수 없습니다${NC}"
    exit 1
fi

# 링크 찾기 (재귀적)
# $1: base_path, $2: broken_only (true/false)
find_all_links() {
    local base_path="$1"
    local broken_only="${2:-false}"
    local links=()

    if [ ! -d "$base_path" ] && [ ! -e "$base_path" ] && [ ! -L "$base_path" ]; then
        return
    fi

    # 현재 경로가 링크면 추가
    if [ -L "$base_path" ]; then
        if [ "$broken_only" = true ]; then
            # 부서진 링크만 추가
            if is_broken_link "$base_path"; then
                echo "$base_path"
            fi
        else
            # 모든 링크 추가
            echo "$base_path"
        fi
        return
    fi

    # 디렉토리면 내부 순회
    if [ -d "$base_path" ]; then
        for item in "$base_path"/*; do
            if [ -e "$item" ] || [ -L "$item" ]; then
                find_all_links "$item" "$broken_only"
            fi
        done
    fi
}

# 심볼릭 링크를 실제 파일/폴더로 교체
replace_link_with_real() {
    local link_path=$1
    local target=$(readlink "$link_path" 2>/dev/null || echo "")
    local temp_path="${link_path}.temp"
    local rel_path="${link_path#$LOCAL_USER_DIR/}"

    echo -n "   🔄 복원 중: $rel_path ... "

    # 대상이 존재하지 않으면 경고
    if [ ! -e "$target" ]; then
        echo -e "${RED}❌${NC}"
        echo -e "      ${YELLOW}경고: iCloud 파일이 없습니다. 링크만 제거됩니다.${NC}"
        rm "$link_path"
        return
    fi

    # 대상 파일/폴더 복사
    if [ -d "$target" ]; then
        cp -R "$target" "$temp_path"
    else
        cp "$target" "$temp_path"
    fi

    # 링크 제거 후 복사본으로 교체
    rm "$link_path"
    mv "$temp_path" "$link_path"

    echo -e "${GREEN}✅${NC}"
}

# 부서진 심볼릭 링크 제거 (복원 없음)
remove_broken_link() {
    local link_path=$1
    local target=$(readlink "$link_path" 2>/dev/null || echo "알 수 없음")
    local rel_path="${link_path#$LOCAL_USER_DIR/}"

    echo -n "   🗑️  제거 중: $rel_path ... "
    rm "$link_path"
    echo -e "${GREEN}✅${NC}"
    echo -e "      ${YELLOW}대상: $target (존재하지 않음)${NC}"
}

# 메인 실행
main() {
    # 설정 정보 출력 (부서진 링크 모드가 아닐 때만)
    if [ "$BROKEN_ONLY" = false ]; then
        print_sync_config
    fi

    # 경로 파싱
    parse_sync_paths

    # 모든 링크 찾기
    if [ "$BROKEN_ONLY" = true ]; then
        echo "🔍 부서진 심볼릭 링크 검색 중..."
    else
        echo "🔍 심볼릭 링크 검색 중..."
    fi
    local all_links=()

    for path in "${PARSED_INCLUDE_PATHS[@]}"; do
        local full_path="$LOCAL_USER_DIR/$path"
        if [ -e "$full_path" ] || [ -L "$full_path" ]; then
            while IFS= read -r link; do
                if [ -n "$link" ]; then
                    all_links+=("$link")
                fi
            done < <(find_all_links "$full_path" "$BROKEN_ONLY")
        fi
    done

    if [ ${#all_links[@]} -eq 0 ]; then
        if [ "$BROKEN_ONLY" = true ]; then
            echo -e "${GREEN}✅ 부서진 심볼릭 링크를 찾을 수 없습니다${NC}"
            echo "   모든 링크가 정상입니다."
        else
            echo -e "${YELLOW}ℹ️  심볼릭 링크를 찾을 수 없습니다${NC}"
            echo "   이미 동기화가 해제되어 있거나 설정되지 않았습니다."
        fi
        exit 0
    fi

    echo ""
    if [ "$BROKEN_ONLY" = true ]; then
        echo "🔍 발견된 부서진 링크: ${#all_links[@]}개"
    else
        echo "🔍 발견된 링크: ${#all_links[@]}개"
    fi
    echo ""
    for link in "${all_links[@]}"; do
        local rel_path="${link#$LOCAL_USER_DIR/}"
        if [ "$BROKEN_ONLY" = true ]; then
            local target=$(readlink "$link" 2>/dev/null || echo "알 수 없음")
            echo -e "   ${RED}✗${NC} $rel_path"
            echo -e "     ${YELLOW}→ $target${NC}"
        else
            echo "   • $rel_path"
        fi
    done
    echo ""

    # 확인 요청
    echo -e "${YELLOW}⚠️  다음 작업을 수행합니다:${NC}"
    if [ "$BROKEN_ONLY" = true ]; then
        echo "   1. 부서진 심볼릭 링크 제거"
        echo "   2. 복원되지 않음 (대상 파일이 없으므로)"
    else
        echo "   1. 모든 심볼릭 링크를 실제 파일/폴더로 복원"
        echo "   2. iCloud 동기화 종료 (iCloud의 파일은 그대로 유지됨)"
    fi
    echo ""
    read -p "계속하시겠습니까? (y/N): " -n 1 -r
    echo

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "취소되었습니다."
        exit 0
    fi

    echo ""
    if [ "$BROKEN_ONLY" = true ]; then
        echo "🗑️  부서진 링크 제거 중..."

        # 각 부서진 링크 제거 (역순으로 - 하위부터)
        for ((i=${#all_links[@]}-1; i>=0; i--)); do
            remove_broken_link "${all_links[$i]}"
        done
    else
        echo "📦 링크를 실제 파일로 복원하는 중..."

        # 각 링크를 실제 파일로 교체 (역순으로 - 하위부터)
        for ((i=${#all_links[@]}-1; i>=0; i--)); do
            replace_link_with_real "${all_links[$i]}"
        done
    fi

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    if [ "$BROKEN_ONLY" = true ]; then
        echo -e "${GREEN}✨ 부서진 링크 제거가 완료되었습니다!${NC}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "💡 현재 상태:"
        echo "   - 부서진 심볼릭 링크가 제거되었습니다"
        echo "   - 올바른 링크는 그대로 유지됩니다"
        echo "   - setup-sync.sh로 누락된 항목을 다시 동기화할 수 있습니다"
    else
        echo -e "${GREEN}✨ 동기화 해제가 완료되었습니다!${NC}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "💡 현재 상태:"
        echo "   - 모든 설정이 로컬 파일로 복원되었습니다"
        echo "   - iCloud의 파일은 그대로 유지됩니다"
        echo "   - 다시 동기화하려면 setup-sync.sh를 실행하세요"
    fi
    echo ""
}

main
