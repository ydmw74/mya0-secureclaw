#!/bin/bash
# Agent Zero SecureClaw - Quick Security Audit
# Adapted from SecureClaw by Adversa AI

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${SCRIPT_DIR}/../configs"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
PASSED=0
FAILED=0
CRITICAL=0
HIGH=0
MEDIUM=0
LOW=0

check() {
    local severity="$1"
    local code="$2"
    local description="$3"
    local result="$4"
    local message="${5:-}"
    
    if [[ "$result" == "PASS" ]]; then
        echo -e "${GREEN}PASS${NC}  [$code] $description"
        ((PASSED++))
    else
        case "$severity" in
            CRIT)
                echo -e "${RED}CRIT${NC}  [$code] $description"
                ((CRITICAL++))
                ;;
            HIGH)
                echo -e "${RED}HIGH${NC}  [$code] $description"
                ((HIGH++))
                ;;
            MED)
                echo -e "${YELLOW}MED${NC}   [$code] $description"
                ((MEDIUM++))
                ;;
            *)
                echo -e "${YELLOW}LOW${NC}   [$code] $description"
                ((LOW++))
                ;;
        esac
        ((FAILED++))
        if [[ -n "$message" ]]; then
            echo "      → $message"
        fi
    fi
}

echo "=========================================="
echo "Agent Zero SecureClaw Security Audit"
echo "=========================================="
echo ""

# Check 1: File permissions on /a0
if [[ -d "/a0" ]]; then
    PERM=$(stat -c "%a" /a0 2>/dev/null || stat -f "%Lp" /a0 2>/dev/null)
    if [[ "$PERM" == "700" || "$PERM" == "755" ]]; then
        check "PASS" "ASI03" "Agent Zero directory permissions" "PASS"
    else
        check "HIGH" "ASI03" "Agent Zero directory permissions" "FAIL" "Current: $PERM, should be 700 or 755"
    fi
else
    check "CRIT" "ASI03" "Agent Zero directory exists" "FAIL" "/a0 not found"
fi

# Check 2: Environment file security
if [[ -f "/a0/.env" ]]; then
    ENV_PERM=$(stat -c "%a" /a0/.env 2>/dev/null || stat -f "%Lp" /a0/.env 2>/dev/null)
    if [[ "$ENV_PERM" == "600" ]]; then
        check "PASS" "ASI03" ".env file permissions" "PASS"
    else
        check "CRIT" "ASI03" ".env file permissions" "FAIL" "Current: $ENV_PERM, should be 600"
    fi
else
    check "INFO" "ASI03" ".env file exists" "PASS" "No .env file found"
fi

# Check 3: Scan for exposed credentials in common locations
echo ""
echo "Scanning for exposed credentials..."
EXPOSED=0
for pattern in "sk-ant-" "sk-proj-" "xoxb-" "xoxp-" "ghp_" "gho_" "AKIA"; do
    if grep -r "$pattern" /a0/usr/workdir/ --include="*.py" --include="*.js" --include="*.json" --include="*.md" --include="*.txt" 2>/dev/null | grep -v ".env" | head -1; then
        EXPOSED=1
    fi
done

if [[ $EXPOSED -eq 0 ]]; then
    check "PASS" "ASI03" "Credential exposure scan" "PASS"
else
    check "CRIT" "ASI03" "Credential exposure scan" "FAIL" "Potential credentials found outside .env"
fi

# Check 4: Check for dangerous patterns in installed skills
if [[ -d "/a0/skills" ]]; then
    echo ""
    echo "Scanning installed skills..."
    SUSPICIOUS=0
    for skill in /a0/skills/*/; do
        if [[ -d "$skill" && "$skill" != *"agent-zero-secureclaw"* ]]; then
            if grep -r "curl.*|.*sh\|wget.*|.*bash\|eval(" "$skill" 2>/dev/null | head -1; then
                SUSPICIOUS=1
                echo "      → Suspicious pattern in: $skill"
            fi
        fi
    done
    
    if [[ $SUSPICIOUS -eq 0 ]]; then
        check "PASS" "ASI04" "Skill supply chain check" "PASS"
    else
        check "HIGH" "ASI04" "Skill supply chain check" "FAIL" "Suspicious patterns found in skills"
    fi
else
    check "INFO" "ASI04" "Skills directory" "PASS" "No skills directory found"
fi

# Check 5: Verify Python virtual environment isolation
if [[ -d "/a0/venv" ]]; then
    check "PASS" "ASI05" "Virtual environment isolation" "PASS"
else
    check "MED" "ASI05" "Virtual environment isolation" "FAIL" "No venv found, recommend using isolated environment"
fi

# Check 6: Check for kill switch
if [[ -f "/a0/usr/workdir/agent-zero-secureclaw/.killswitch" ]]; then
    check "CRIT" "ASI10" "Kill switch status" "FAIL" "Kill switch is ACTIVE - all operations should be suspended"
else
    check "PASS" "ASI10" "Kill switch status" "PASS"
fi

# Check 7: Memory/integrity baselines
echo ""
if [[ -d "/a0/usr/workdir/agent-zero-secureclaw/.baselines" ]]; then
    check "PASS" "ASI06" "Cognitive file baselines" "PASS"
else
    check "MED" "ASI06" "Cognitive file baselines" "FAIL" "No baselines found - run check-integrity.sh to create"
fi

# Summary
echo ""
echo "=========================================="
echo "Audit Summary"
echo "=========================================="
TOTAL=$((PASSED + FAILED))
SCORE=$((PASSED * 100 / TOTAL))
echo "Score: $SCORE/100 ($PASSED/$TOTAL checks passed)"
echo ""
echo "Breakdown:"
echo "  Critical: $CRITICAL"
echo "  High:     $HIGH"
echo "  Medium:   $MEDIUM"
echo "  Low:      $LOW"
echo ""

if [[ $CRITICAL -gt 0 ]]; then
    echo -e "${RED}CRITICAL issues found. Immediate action required.${NC}"
    exit 2
elif [[ $HIGH -gt 0 ]]; then
    echo -e "${YELLOW}HIGH severity issues found. Review recommended.${NC}"
    exit 1
else
    echo -e "${GREEN}No critical or high severity issues.${NC}"
    exit 0
fi
