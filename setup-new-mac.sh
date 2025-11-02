#!/bin/bash

# 🚀 새 Mac에서 Cursor 완전 셋업
# 설정 동기화 + 확장 프로그램 설치를 한 번에 수행합니다

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# 현재 스크립트의 디렉토리
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

clear

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}${CYAN}    🎉 Cursor 완전 셋업 스크립트${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BLUE}이 스크립트는 다음 작업을 수행합니다:${NC}"
echo "  1️⃣  Cursor 설정 동기화 (심볼릭 링크)"
echo "  2️⃣  확장 프로그램 일괄 설치"
echo ""
echo -e "${YELLOW}⚠️  주의: Cursor가 실행 중이라면 먼저 종료해주세요${NC}"
echo ""

read -p "계속하시겠습니까? (y/N): " -n 1 -r
echo
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "취소되었습니다."
    exit 0
fi

# Step 1: 설정 동기화
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}Step 1/2: Cursor 설정 동기화${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if [ ! -f "$SCRIPT_DIR/setup-sync.sh" ]; then
    echo -e "${RED}❌ setup-sync.sh를 찾을 수 없습니다${NC}"
    exit 1
fi

bash "$SCRIPT_DIR/setup-sync.sh"

if [ $? -ne 0 ]; then
    echo ""
    echo -e "${RED}❌ 설정 동기화에 실패했습니다${NC}"
    echo "   setup-sync.sh를 단독으로 실행하여 문제를 확인하세요."
    exit 1
fi

echo ""
echo -e "${GREEN}✅ Step 1 완료!${NC}"
echo ""
sleep 2

# Step 2: 확장 프로그램 설치
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}Step 2/2: 확장 프로그램 설치${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 가장 최신 install 스크립트 찾기
LATEST_INSTALL=$(ls -t "$SCRIPT_DIR"/install-extensions-*.sh 2>/dev/null | head -1)

if [ -z "$LATEST_INSTALL" ]; then
    echo -e "${YELLOW}⚠️  확장 프로그램 설치 스크립트를 찾을 수 없습니다${NC}"
    echo ""
    echo "💡 다른 Mac에서 다음 명령을 실행하여 스크립트를 생성하세요:"
    echo "   bash export-extensions.sh"
    echo ""
    echo -e "${BLUE}설정 동기화는 완료되었습니다.${NC}"
    echo "확장 프로그램은 나중에 수동으로 설치할 수 있습니다."
    exit 0
fi

echo "📦 발견된 설치 스크립트: $(basename "$LATEST_INSTALL")"
echo ""

bash "$LATEST_INSTALL"

if [ $? -ne 0 ]; then
    echo ""
    echo -e "${YELLOW}⚠️  일부 확장 프로그램 설치에 실패했습니다${NC}"
    echo "   Cursor를 실행한 후 수동으로 설치할 수 있습니다."
fi

echo ""
echo -e "${GREEN}✅ Step 2 완료!${NC}"
echo ""
sleep 1

# 완료
clear

echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}${GREEN}    ✨ 셋업 완료! ✨${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BLUE}✅ 완료된 작업:${NC}"
echo "   • Cursor 설정이 iCloud와 동기화되었습니다"
echo "   • 확장 프로그램이 설치되었습니다"
echo ""
echo -e "${CYAN}🎯 다음 단계:${NC}"
echo "   1. Cursor를 실행하세요"
echo "   2. 설정이 모두 적용되었는지 확인하세요"
echo "   3. 필요한 경우 추가 확장을 설치하세요"
echo ""
echo -e "${YELLOW}💡 팁:${NC}"
echo "   • 설정은 자동으로 iCloud와 동기화됩니다"
echo "   • 확장을 추가/제거했다면 export-extensions.sh를 실행하세요"
echo "   • 문제가 있다면 README.md를 참고하세요"
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "🚀 즐거운 코딩 되세요!"
echo ""



