#!/bin/bash

# Cursor 설정 iCloud 동기화 해제 스크립트
# 심볼릭 링크를 제거하고 실제 파일로 복원합니다

set -e

# 설정 파일 로드
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/sync-config.sh"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔓 Cursor 설정 iCloud 동기화 해제"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# User 디렉토리 존재 확인
if [ ! -d "$LOCAL_USER_DIR" ]; then
    echo -e "${RED}❌ User 디렉토리를 찾을 수 없습니다${NC}"
    exit 1
fi

# 링크 찾기 (재귀적)
find_all_links() {
    local base_path="$1"
    local links=()
    
    if [ ! -d "$base_path" ] && [ ! -e "$base_path" ]; then
        return
    fi
    
    # 현재 경로가 링크면 추가
    if [ -L "$base_path" ]; then
        echo "$base_path"
        return
    fi
    
    # 디렉토리면 내부 순회
    if [ -d "$base_path" ]; then
        for item in "$base_path"/*; do
            if [ -e "$item" ] || [ -L "$item" ]; then
                find_all_links "$item"
            fi
        done
    fi
}

# 심볼릭 링크를 실제 파일/폴더로 교체
replace_link_with_real() {
    local link_path=$1
    local target=$(readlink "$link_path")
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

# 메인 실행
main() {
    # 설정 정보 출력
    print_sync_config
    
    # 경로 파싱
    parse_sync_paths
    
    # 모든 링크 찾기
    echo "🔍 심볼릭 링크 검색 중..."
    local all_links=()
    
    for path in "${PARSED_INCLUDE_PATHS[@]}"; do
        local full_path="$LOCAL_USER_DIR/$path"
        if [ -e "$full_path" ] || [ -L "$full_path" ]; then
            while IFS= read -r link; do
                if [ -n "$link" ]; then
                    all_links+=("$link")
                fi
            done < <(find_all_links "$full_path")
        fi
    done
    
    if [ ${#all_links[@]} -eq 0 ]; then
        echo -e "${YELLOW}ℹ️  심볼릭 링크를 찾을 수 없습니다${NC}"
        echo "   이미 동기화가 해제되어 있거나 설정되지 않았습니다."
        exit 0
    fi
    
    echo ""
    echo "🔍 발견된 링크: ${#all_links[@]}개"
    echo ""
    for link in "${all_links[@]}"; do
        local rel_path="${link#$LOCAL_USER_DIR/}"
        echo "   • $rel_path"
    done
    echo ""
    
    # 확인 요청
    echo -e "${YELLOW}⚠️  다음 작업을 수행합니다:${NC}"
    echo "   1. 모든 심볼릭 링크를 실제 파일/폴더로 복원"
    echo "   2. iCloud 동기화 종료 (iCloud의 파일은 그대로 유지됨)"
    echo ""
    read -p "계속하시겠습니까? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "취소되었습니다."
        exit 0
    fi
    
    echo ""
    echo "📦 링크를 실제 파일로 복원하는 중..."
    
    # 각 링크를 실제 파일로 교체 (역순으로 - 하위부터)
    for ((i=${#all_links[@]}-1; i>=0; i--)); do
        replace_link_with_real "${all_links[$i]}"
    done
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${GREEN}✨ 동기화 해제가 완료되었습니다!${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "💡 현재 상태:"
    echo "   - 모든 설정이 로컬 파일로 복원되었습니다"
    echo "   - iCloud의 파일은 그대로 유지됩니다"
    echo "   - 다시 동기화하려면 setup-sync.sh를 실행하세요"
    echo ""
}

main
