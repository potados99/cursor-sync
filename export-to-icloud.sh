#!/bin/bash

# Cursor 설정을 iCloud로 백업하는 스크립트
# 첫 Mac에서 실행하여 설정을 iCloud에 저장합니다

set -e

# 설정 파일 로드
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/sync-config.sh"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📤 Cursor 설정을 iCloud로 백업"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 로컬 User 디렉토리 존재 확인
if [ ! -d "$LOCAL_USER_DIR" ]; then
    echo -e "${RED}❌ 오류: 로컬 User 디렉토리를 찾을 수 없습니다${NC}"
    echo "   경로: $LOCAL_USER_DIR"
    exit 1
fi

# iCloud 디렉토리 생성
ensure_icloud_dir

# 재귀적으로 복사 (제외 항목 스킵)
recursive_copy() {
    local rel_path="$1"
    local source="$LOCAL_USER_DIR/$rel_path"
    local target="$ICLOUD_DIR/$rel_path"
    
    # 제외 대상이면 스킵
    if is_excluded "$rel_path"; then
        echo "   ⏭️  제외: $rel_path"
        return
    fi
    
    # 하위에 제외 항목이 없으면 통째로 복사
    if ! has_exclusions_under "$rel_path"; then
        copy_item "$rel_path"
        return
    fi
    
    # 하위에 제외 항목이 있으면 재귀적으로 처리
    if [ ! -d "$source" ]; then
        copy_item "$rel_path"
        return
    fi
    
    # 디렉토리 순회
    for item in "$source"/*; do
        if [ ! -e "$item" ]; then
            continue
        fi
        
        local item_name=$(basename "$item")
        local item_rel_path="$rel_path/$item_name"
        
        recursive_copy "$item_rel_path"
    done
}

# 파일/폴더 복사
copy_item() {
    local rel_path="$1"
    local source="$LOCAL_USER_DIR/$rel_path"
    local target="$ICLOUD_DIR/$rel_path"
    
    if [ ! -e "$source" ]; then
        return
    fi
    
    # 링크인 경우 실제 파일로 복사
    if [ -L "$source" ]; then
        local real_source=$(readlink "$source")
        echo -n "   📦 백업 중 (링크): $rel_path ... "
        
        if [ ! -e "$real_source" ]; then
            echo -e "${YELLOW}⚠️  링크 대상 없음${NC}"
            return
        fi
        
        # 대상 디렉토리 생성
        local target_dir=$(dirname "$target")
        mkdir -p "$target_dir"
        
        # 기존 파일 제거
        if [ -e "$target" ]; then
            rm -rf "$target"
        fi
        
        if [ -d "$real_source" ]; then
            cp -R "$real_source" "$target"
        else
            cp "$real_source" "$target"
        fi
        echo -e "${GREEN}✅${NC}"
        return
    fi
    
    echo -n "   📦 백업 중: $rel_path ... "
    
    # 대상 디렉토리 생성
    local target_dir=$(dirname "$target")
    mkdir -p "$target_dir"
    
    # 대상이 이미 존재하면 덮어쓸지 확인
    if [ -e "$target" ]; then
        echo -e "${YELLOW}이미 존재${NC}"
        read -p "      덮어쓰시겠습니까? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "      ⏭️  건너뜀"
            return
        fi
        rm -rf "$target"
    fi
    
    if [ -d "$source" ]; then
        cp -R "$source" "$target"
    else
        cp "$source" "$target"
    fi
    
    echo -e "${GREEN}✅${NC}"
}

# 메인 실행
main() {
    # 설정 정보 출력
    print_sync_config
    
    echo "📁 소스: $LOCAL_USER_DIR"
    echo "📁 대상: $ICLOUD_DIR"
    echo ""
    
    # 확인
    read -p "계속하시겠습니까? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "취소되었습니다."
        exit 0
    fi
    
    echo ""
    
    # 경로 파싱
    parse_sync_paths
    
    # 백업 시작
    echo "⚙️  백업 중..."
    echo ""
    
    for path in "${PARSED_INCLUDE_PATHS[@]}"; do
        echo "📦 처리 중: $path"
        recursive_copy "$path"
        echo ""
    done
    
    echo -e "${GREEN}✅ 백업 완료${NC}"
    echo ""
    
    # 완료
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${GREEN}✨ iCloud 백업이 완료되었습니다!${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "📁 백업 위치: $ICLOUD_DIR"
    echo ""
    echo "💡 다음 단계:"
    echo "   1. iCloud 동기화가 완료될 때까지 기다립니다"
    echo "   2. 다른 Mac에서 setup-sync.sh를 실행합니다"
    echo ""
}

main
