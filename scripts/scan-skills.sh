#!/bin/bash
# Agent Zero SecureClaw - Skill Supply Chain Scanner
# Scans skills for malicious patterns

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="${SCRIPT_DIR}/../configs/supply-chain-ioc.json"

TARGET="${1:-/a0/skills}"

echo "Agent Zero SecureClaw - Skill Scanner"
echo "======================================"
echo "Target: $TARGET"
echo ""

if [[ ! -d "$TARGET" ]]; then
    echo "No skills directory found at $TARGET"
    exit 0
fi

SUSPICIOUS=0

for skill in "$TARGET"/*/; do
    if [[ -d "$skill" ]]; then
        SKILL_NAME=$(basename "$skill")
        echo "Scanning: $SKILL_NAME"
        
        # Skip self
        if [[ "$SKILL_NAME" == *"agent-zero-secureclaw"* ]]; then
            echo "  → Skipping (self)"
            continue
        fi
        
        ISSUES=0
        
        # Check for remote code execution patterns
        if grep -rE "curl.*\|.*(sh|bash)|wget.*\|.*(sh|bash)" "$skill" 2>/dev/null; then
            echo "  ❌ REMOTE CODE EXECUTION: curl/wget pipe to shell"
            ISSUES=1
        fi
        
        # Check for eval/exec
        if grep -rE "eval\(|exec\(|Function\(" "$skill" 2>/dev/null; then
            echo "  ⚠️  DYNAMIC EXECUTION: eval/exec/Function detected"
            ISSUES=1
        fi
        
        # Check for credential access
        if grep -rE "process\.env|\.env|apiKey|token" "$skill" 2>/dev/null | head -3; then
            echo "  ⚠️  CREDENTIAL ACCESS: References to credentials"
            ISSUES=1
        fi
        
        # Check for config tampering
        if grep -rE "SOUL\.md|IDENTITY\.md|openclaw\.json|agent.*system.*md" "$skill" 2>/dev/null; then
            echo "  ⚠️  CONFIG TAMPERING: References to cognitive files"
            ISSUES=1
        fi
        
        if [[ $ISSUES -eq 0 ]]; then
            echo "  ✓ Clean"
        else
            SUSPICIOUS=1
        fi
    fi
done

echo ""
if [[ $SUSPICIOUS -eq 0 ]]; then
    echo "✓ All skills scanned, no suspicious patterns found"
    exit 0
else
    echo "⚠️  Suspicious patterns detected. Review before installing."
    exit 1
fi
