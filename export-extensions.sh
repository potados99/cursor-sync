#!/bin/bash

# Cursor 확장 프로그램 백업 스크립트
# 실행하면 현재 설치된 확장 프로그램 목록으로 install 스크립트를 생성합니다

set -e

# 현재 스크립트의 디렉토리 경로
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 현재 날짜와 시간 (YYYY-MM-DD-HHMMSS 형식)
TIMESTAMP=$(date +"%Y-%m-%d-%H%M%S")

# 생성될 install 스크립트 파일명
INSTALL_SCRIPT="${SCRIPT_DIR}/install-extensions-${TIMESTAMP}.sh"

echo "🔍 Cursor 확장 프로그램 목록을 가져오는 중..."

# Cursor 확장 프로그램 목록 가져오기
EXTENSIONS=$(cursor --list-extensions 2>/dev/null || code --list-extensions 2>/dev/null || echo "")

if [ -z "$EXTENSIONS" ]; then
    echo "❌ 확장 프로그램 목록을 가져올 수 없습니다."
    echo "   Cursor가 설치되어 있고 PATH에 등록되어 있는지 확인하세요."
    exit 1
fi

# 확장 프로그램 개수 계산
EXT_COUNT=$(echo "$EXTENSIONS" | wc -l | tr -d ' ')

echo "✅ ${EXT_COUNT}개의 확장 프로그램을 찾았습니다."
echo ""
echo "📝 Install 스크립트 생성 중: $(basename "$INSTALL_SCRIPT")"

# Install 스크립트 생성
cat > "$INSTALL_SCRIPT" << 'SCRIPT_HEADER'
#!/bin/bash

# Cursor 확장 프로그램 설치 스크립트
SCRIPT_HEADER

echo "# 생성일: $(date '+%Y-%m-%d %H:%M:%S')" >> "$INSTALL_SCRIPT"
echo "# 총 ${EXT_COUNT}개의 확장 프로그램" >> "$INSTALL_SCRIPT"
echo "" >> "$INSTALL_SCRIPT"

cat >> "$INSTALL_SCRIPT" << 'SCRIPT_BODY'
set -e

echo "🚀 Cursor 확장 프로그램 설치를 시작합니다..."
echo ""

TOTAL=0
SUCCESS=0
FAILED=0

# 확장 프로그램 목록
EXTENSIONS=(
SCRIPT_BODY

# 확장 프로그램 목록을 배열 형태로 추가
while IFS= read -r ext; do
    echo "    \"$ext\"" >> "$INSTALL_SCRIPT"
done <<< "$EXTENSIONS"

cat >> "$INSTALL_SCRIPT" << 'SCRIPT_FOOTER'
)

TOTAL=${#EXTENSIONS[@]}

# 각 확장 프로그램 설치
for ext in "${EXTENSIONS[@]}"; do
    echo -n "📦 설치 중: $ext ... "
    
    if cursor --install-extension "$ext" --force > /dev/null 2>&1 || code --install-extension "$ext" --force > /dev/null 2>&1; then
        echo "✅"
        ((SUCCESS++))
    else
        echo "❌"
        ((FAILED++))
    fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 설치 완료!"
echo "   총: $TOTAL개"
echo "   성공: $SUCCESS개"
echo "   실패: $FAILED개"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ $FAILED -eq 0 ]; then
    echo "✨ 모든 확장 프로그램이 성공적으로 설치되었습니다!"
    exit 0
else
    echo "⚠️  일부 확장 프로그램 설치에 실패했습니다."
    exit 1
fi
SCRIPT_FOOTER

# 실행 권한 부여
chmod +x "$INSTALL_SCRIPT"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✨ Install 스크립트가 생성되었습니다!"
echo ""
echo "📁 위치: $INSTALL_SCRIPT"
echo ""
echo "🔧 사용 방법:"
echo "   다른 Mac에서 다음 명령어를 실행하세요:"
echo "   bash \"$INSTALL_SCRIPT\""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📋 백업된 확장 프로그램 목록:"
echo "$EXTENSIONS" | sed 's/^/   - /'




