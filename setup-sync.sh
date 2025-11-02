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

# 최초 실행 시 User 디렉토리 전체 백업
backup_user_dir_if_first_run() {
    local marker_file="$BACKUP_DIR/.full_backup_done"

    # 마커 파일이 있으면 이미 백업한 것으로 간주
    if [ -f "$marker_file" ]; then
        return
    fi

    echo "🎯 최초 실행 감지"
    echo ""

    # User 디렉토리가 존재하고 비어있지 않으면 백업
    if [ -d "$LOCAL_USER_DIR" ] && [ "$(ls -A "$LOCAL_USER_DIR" 2>/dev/null)" ]; then
        local timestamp=$(get_timestamp)
        local full_backup="$BACKUP_DIR/User.full.$timestamp"

        echo "💾 User 디렉토리 전체 백업 중..."
        echo "   소스: $LOCAL_USER_DIR"
        echo "   대상: $full_backup"
        echo ""

        cp -R "$LOCAL_USER_DIR" "$full_backup"

        echo -e "${GREEN}✅ 전체 백업 완료${NC}"
        echo ""

        # 마커 파일 생성
        touch "$marker_file"
        echo "최초 실행 시 생성됨: $(date)" > "$marker_file"
    else
        # User 디렉토리가 없거나 비어있으면 마커만 생성
        touch "$marker_file"
        echo "User 디렉토리 없음 (마커만 생성): $(date)" > "$marker_file"
    fi
}

# 기존 링크 분석 및 처리 계획 수립
analyze_existing_links() {
    local correct_links=()
    local broken_links=()
    local wrong_target_links=()
    local missing_links=()

    echo "🔍 기존 동기화 상태 확인 중..."
    echo ""

    # 경로 파싱
    parse_sync_paths

    # 각 포함 경로 확인
    for path in "${PARSED_INCLUDE_PATHS[@]}"; do
        local source="$LOCAL_USER_DIR/$path"

        # 링크인지 확인
        if [ -L "$source" ]; then
            if is_broken_link "$source"; then
                broken_links+=("$path")
            elif is_correct_link "$path"; then
                correct_links+=("$path")
            else
                wrong_target_links+=("$path")
            fi
        else
            # 링크가 아니면 누락된 것
            missing_links+=("$path")
        fi
    done

    # 상태 출력
    if [ ${#correct_links[@]} -gt 0 ]; then
        echo -e "${GREEN}✅ 올바른 링크: ${#correct_links[@]}개${NC}"
    fi

    if [ ${#broken_links[@]} -gt 0 ]; then
        echo -e "${RED}⚠️  부서진 링크: ${#broken_links[@]}개${NC}"
        for path in "${broken_links[@]}"; do
            echo "   • $path"
        done
    fi

    if [ ${#wrong_target_links[@]} -gt 0 ]; then
        echo -e "${YELLOW}⚠️  잘못된 대상 링크: ${#wrong_target_links[@]}개${NC}"
        for path in "${wrong_target_links[@]}"; do
            echo "   • $path"
        done
    fi

    if [ ${#missing_links[@]} -gt 0 ]; then
        echo -e "${YELLOW}📝 누락된 항목: ${#missing_links[@]}개${NC}"
        for path in "${missing_links[@]}"; do
            echo "   • $path"
        done
    fi

    echo ""

    # 전역 변수로 반환
    CORRECT_LINKS=("${correct_links[@]}")
    BROKEN_LINKS=("${broken_links[@]}")
    WRONG_TARGET_LINKS=("${wrong_target_links[@]}")
    MISSING_LINKS=("${missing_links[@]}")

    # 수정이 필요한지 반환
    if [ ${#broken_links[@]} -gt 0 ] || [ ${#wrong_target_links[@]} -gt 0 ] || [ ${#missing_links[@]} -gt 0 ]; then
        return 0  # 수정 필요
    else
        return 1  # 모두 올바름
    fi
}

# 메인 실행
main() {
    # 설정 정보 출력
    print_sync_config

    # 1. 최초 실행 시 전체 백업
    backup_user_dir_if_first_run

    # 2. 기존 링크 분석
    if analyze_existing_links; then
        # 수정이 필요함
        echo "🔧 수정이 필요한 항목이 있습니다."
        echo ""

        # 부서진 링크 수리
        if [ ${#BROKEN_LINKS[@]} -gt 0 ]; then
            echo "🔨 부서진 링크 수리 중..."
            for path in "${BROKEN_LINKS[@]}"; do
                local source="$LOCAL_USER_DIR/$path"
                echo "   🗑️  제거: $path (부서진 링크)"
                rm "$source"
            done
            echo ""
        fi

        # 잘못된 대상 링크 수리
        if [ ${#WRONG_TARGET_LINKS[@]} -gt 0 ]; then
            echo "🔨 잘못된 링크 수리 중..."
            for path in "${WRONG_TARGET_LINKS[@]}"; do
                local source="$LOCAL_USER_DIR/$path"
                echo "   🗑️  제거: $path (잘못된 대상)"
                rm "$source"
            done
            echo ""
        fi
    else
        # 모두 올바름
        echo -e "${GREEN}✅ 모든 항목이 이미 올바르게 동기화되어 있습니다!${NC}"
        echo ""
        echo "💡 변경사항이 없으므로 작업을 종료합니다."
        echo "   설정을 변경하려면 sync-config.sh를 수정한 후 다시 실행하세요."
        echo ""
        exit 0
    fi

    # 3. 경로 파싱
    parse_sync_paths

    # 4. 누락된 항목 동기화
    echo "⚙️  누락된 항목 동기화 중..."
    echo ""

    # 수정이 필요한 항목만 처리
    for path in "${BROKEN_LINKS[@]}" "${WRONG_TARGET_LINKS[@]}" "${MISSING_LINKS[@]}"; do
        if [ -n "$path" ]; then
            echo "📦 처리 중: $path"
            recursive_link_path "$path" 0
            echo ""
        fi
    done

    echo -e "${GREEN}✅ 동기화 완료${NC}"
    echo ""

    # 5. 완료
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
        local status=""
        if [[ " ${CORRECT_LINKS[@]} " =~ " $path " ]]; then
            status=" ${GREEN}(이미 동기화됨)${NC}"
        elif [[ " ${BROKEN_LINKS[@]} ${WRONG_TARGET_LINKS[@]} ${MISSING_LINKS[@]} " =~ " $path " ]]; then
            status=" ${YELLOW}(수리/추가됨)${NC}"
        fi
        echo -e "   • $path$status"
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
