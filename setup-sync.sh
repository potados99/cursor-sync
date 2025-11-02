#!/bin/bash

# Cursor 설정 iCloud 동기화 셋업 스크립트
# ~/Library/Application Support/Cursor/User/ 와 iCloud를 심볼릭 링크로 연결합니다

set -e

# 설정 파일 로드
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/sync-config.sh"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔗 Cursor 설정 iCloud 동기화 셋업"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 경로 유효성 검사
if ! validate_paths; then
    exit 1
fi

# 로컬 디렉토리 생성
ensure_local_dir
ensure_backup_dir

# 이미 링크가 있는지 확인
check_existing_links() {
    local has_links=false
    
    echo "🔍 기존 심볼릭 링크 확인 중..."
    
    # 경로 파싱
    parse_sync_paths
    
    # 각 포함 경로 확인
    for path in "${PARSED_INCLUDE_PATHS[@]}"; do
        local source="$LOCAL_USER_DIR/$path"
        
        # 링크인지 확인
        if [ -L "$source" ]; then
            echo -e "${YELLOW}   ⚠️  이미 링크됨: $path${NC}"
            has_links=true
            continue
        fi
        
        # 디렉토리이고 하위에 제외가 있으면 내부도 확인
        if [ -d "$source" ] && has_exclusions_under "$path"; then
            for item in "$source"/*; do
                if [ -L "$item" ]; then
                    local item_name=$(basename "$item")
                    echo -e "${YELLOW}   ⚠️  이미 링크됨: $path/$item_name${NC}"
                    has_links=true
                fi
            done
        fi
    done
    
    if [ "$has_links" = true ]; then
        echo ""
        echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${RED}❌ 이미 심볼릭 링크가 존재합니다!${NC}"
        echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo "💡 링크를 제거하려면 다음 스크립트를 실행하세요:"
        echo "   bash unlink-sync.sh"
        echo ""
        exit 1
    fi
    
    echo -e "${GREEN}✅ 기존 링크 없음. 계속 진행합니다.${NC}"
    echo ""
}

# 메인 실행
main() {
    # 설정 정보 출력
    print_sync_config
    
    # 1. 기존 링크 확인
    check_existing_links
    
    # 2. 경로 파싱
    parse_sync_paths
    
    # 3. 동기화 시작
    echo "⚙️  동기화 중..."
    echo ""
    
    for path in "${PARSED_INCLUDE_PATHS[@]}"; do
        echo "📦 처리 중: $path"
        recursive_link_path "$path" 0
        echo ""
    done
    
    echo -e "${GREEN}✅ 동기화 완료${NC}"
    echo ""
    
    # 4. 완료
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${GREEN}✨ 동기화 셋업이 완료되었습니다!${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "📁 iCloud 위치: $ICLOUD_DIR"
    echo "🔗 로컬 위치: $LOCAL_USER_DIR"
    echo ""
    echo "💾 백업 위치: $BACKUP_DIR"
    echo "   (원본 파일들이 타임스탬프와 함께 백업되었습니다)"
    echo ""
    echo "✅ 동기화된 항목:"
    for path in "${PARSED_INCLUDE_PATHS[@]}"; do
        echo "   • $path"
    done
    
    if [ ${#PARSED_EXCLUDE_PATHS[@]} -gt 0 ]; then
        echo ""
        echo "⏭️  제외된 항목 (로컬에만 유지):"
        for path in "${PARSED_EXCLUDE_PATHS[@]}"; do
            echo "   • $path"
        done
    fi
    
    echo ""
    echo "⚠️  주의사항:"
    echo "   - 여러 Mac에서 동시에 Cursor를 사용하면 충돌이 발생할 수 있습니다"
    echo "   - iCloud 동기화가 완료될 때까지 잠시 기다려주세요"
    echo "   - 설정을 변경하려면 sync-config.sh를 수정하세요"
    echo ""
}

main
