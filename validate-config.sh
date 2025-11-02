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
    
    if [ "$is_link" = true ]; then
        echo -e "    ${BLUE}→ 이미 링크됨${NC}"
    else
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

# 5. 경고 및 권장사항
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

# 6. 완료
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

