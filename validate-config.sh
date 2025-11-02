#!/bin/bash

# 동기화 설정 검증 도구
# 설정 파일의 유효성을 확인하고 어떻게 동작할지 미리 보여줍니다

set -e

# 설정 파일 로드
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/sync-config.sh"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 동기화 설정 검증"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 경로 파싱
parse_sync_paths

# 1. 설정 요약
echo "📋 설정 요약"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  총 ${#SYNC_PATHS[@]}개 경로 정의됨"
echo "  → 포함: ${#PARSED_INCLUDE_PATHS[@]}개"
echo "  → 제외: ${#PARSED_EXCLUDE_PATHS[@]}개"
echo ""

# 2. 포함 경로 상세
echo "✅ 포함 경로 (${#PARSED_INCLUDE_PATHS[@]}개)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
for path in "${PARSED_INCLUDE_PATHS[@]}"; do
    source="$LOCAL_USER_DIR/$path"
    target="$ICLOUD_DIR/$path"
    
    # 존재 여부 확인
    exists_local=false
    exists_icloud=false
    is_link=false
    
    if [ -e "$source" ]; then
        exists_local=true
        if [ -L "$source" ]; then
            is_link=true
        fi
    fi
    
    if [ -e "$target" ]; then
        exists_icloud=true
    fi
    
    # 하위 제외 확인
    has_exclusions=""
    if has_exclusions_under "$path"; then
        has_exclusions=" ${YELLOW}(재귀적 처리 필요)${NC}"
    fi
    
    # 출력
    echo -e "  • $path$has_exclusions"

    # 로컬과 iCloud 둘 다 없으면 경고
    if [ "$exists_local" = false ] && [ "$exists_icloud" = false ]; then
        echo -e "    ${YELLOW}ℹ️  설정에 명시되어 있지만 실제로 존재하지 않습니다${NC}"
        echo -e "    ${YELLOW}   (setup-sync 실행 시 무시됨)${NC}"
    elif [ "$is_link" = true ]; then
        # 링크 대상 확인
        if is_broken_link "$source"; then
            echo -e "    ${RED}✗ 부서진 링크!${NC}"
            local link_target=$(readlink "$source")
            echo -e "    ${YELLOW}  대상: $link_target (존재하지 않음)${NC}"
        elif is_correct_link "$path"; then
            echo -e "    ${GREEN}✓ 올바른 링크${NC}"
        else
            local link_target=$(readlink "$source")
            echo -e "    ${YELLOW}⚠ 잘못된 링크 대상${NC}"
            echo -e "    ${YELLOW}  현재: $link_target${NC}"
            echo -e "    ${YELLOW}  예상: $target${NC}"
        fi
    else
        # 재귀적 처리 필요한 경로는 디렉토리 자체가 링크가 아닌 게 정상
        if has_exclusions_under "$path"; then
            if [ -d "$source" ] || [ -d "$target" ]; then
                echo -e "    ${CYAN}→ 재귀적 처리 (내부 항목 개별 링크)${NC}"
            fi
        fi

        if [ "$exists_local" = true ]; then
            echo -e "    ${GREEN}✓ 로컬 존재${NC}"
        else
            echo -e "    ${YELLOW}✗ 로컬 없음${NC}"
        fi

        if [ "$exists_icloud" = true ]; then
            echo -e "    ${GREEN}✓ iCloud 존재${NC}"
        else
            echo -e "    ${YELLOW}✗ iCloud 없음${NC}"
        fi
    fi

    echo ""
done

# 3. 제외 경로 상세
if [ ${#PARSED_EXCLUDE_PATHS[@]} -gt 0 ]; then
    echo ""
    echo "⊝ 제외 경로 (${#PARSED_EXCLUDE_PATHS[@]}개)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    for path in "${PARSED_EXCLUDE_PATHS[@]}"; do
        source="$LOCAL_USER_DIR/$path"
        
        # 존재 여부 확인
        exists=false
        if [ -e "$source" ]; then
            exists=true
        fi
        
        echo -e "  • $path"
        if [ "$exists" = true ]; then
            echo -e "    ${GREEN}✓ 로컬 존재 (유지됨)${NC}"
        else
            echo -e "    ${YELLOW}✗ 로컬 없음${NC}"
        fi
        echo ""
    done
fi

# 4. 예상 동작 시뮬레이션
echo ""
echo "🎬 예상 동작"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

for path in "${PARSED_INCLUDE_PATHS[@]}"; do
    echo "📦 $path"
    
    if has_exclusions_under "$path"; then
        echo "   → 재귀적으로 순회하며 다음 항목 제외:"
        for exclude in "${PARSED_EXCLUDE_PATHS[@]}"; do
            if is_subpath "$exclude" "$path"; then
                echo "      ⊝ $exclude"
            fi
        done
    else
        echo "   → 통째로 심볼릭 링크"
    fi
    echo ""
done

# 5. 부서진 링크 검사
echo ""
echo "🔍 부서진 링크 검사"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

broken_links=()
for path in "${PARSED_INCLUDE_PATHS[@]}"; do
    full_path="$LOCAL_USER_DIR/$path"
    if [ -e "$full_path" ] || [ -L "$full_path" ]; then
        while IFS= read -r link; do
            if [ -n "$link" ]; then
                broken_links+=("$link")
            fi
        done < <(find_broken_links "$full_path")
    fi
done

if [ ${#broken_links[@]} -gt 0 ]; then
    echo -e "${RED}⚠️  발견된 부서진 링크: ${#broken_links[@]}개${NC}"
    echo ""
    for link in "${broken_links[@]}"; do
        rel_path="${link#$LOCAL_USER_DIR/}"
        link_target=$(readlink "$link" 2>/dev/null || echo "알 수 없음")
        echo -e "  ${RED}✗${NC} $rel_path"
        echo -e "    ${YELLOW}→ $link_target${NC}"
    done
    echo ""
    echo -e "${YELLOW}💡 조치 방법:${NC}"
    echo "   1. unlink-sync.sh --broken 으로 부서진 링크 제거"
    echo "   2. setup-sync.sh 로 다시 동기화 설정"
    echo ""
else
    echo -e "  ${GREEN}✅ 부서진 링크 없음${NC}"
    echo ""
fi

# 6. 경고 및 권장사항
echo ""
echo "⚠️  경고 및 권장사항"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

warnings=0

# 위험한 항목 체크
dangerous_paths=(
    "CachedData"
    "logs"
    "History"
)

for path in "${PARSED_INCLUDE_PATHS[@]}"; do
    for dangerous in "${dangerous_paths[@]}"; do
        if [[ "$path" == "$dangerous"* ]]; then
            echo -e "  ${RED}⚠️  경고: $path${NC}"
            echo "     이 항목은 동기화하지 않는 것을 권장합니다 (캐시/로그 데이터)"
            echo ""
            ((warnings++))
        fi
    done
done

# DB 파일 체크
for path in "${PARSED_INCLUDE_PATHS[@]}"; do
    if [[ "$path" == "globalStorage" ]]; then
        has_vscdb_exclusion=false
        for exclude in "${PARSED_EXCLUDE_PATHS[@]}"; do
            if [[ "$exclude" == "globalStorage/state.vscdb" ]]; then
                has_vscdb_exclusion=true
                break
            fi
        done
        
        if [ "$has_vscdb_exclusion" = false ]; then
            echo -e "  ${YELLOW}💡 권장: globalStorage를 동기화하는 경우${NC}"
            echo "     state.vscdb 파일들을 제외하는 것을 권장합니다"
            echo "     (Mac마다 다른 내부 상태 정보)"
            echo ""
            ((warnings++))
        fi
    fi
done

if [ $warnings -eq 0 ]; then
    echo -e "  ${GREEN}✅ 문제 없음${NC}"
    echo ""
fi

# 7. 완료
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}✨ 검증 완료${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "💡 다음 단계:"
if [ ${#PARSED_INCLUDE_PATHS[@]} -eq 0 ]; then
    echo "   ⚠️  포함 경로가 없습니다. sync-config.sh를 확인하세요."
else
    echo "   1. 설정이 올바르면 setup-sync.sh 실행"
    echo "   2. 수정이 필요하면 sync-config.sh 편집"
fi
echo ""

