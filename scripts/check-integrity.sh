#!/bin/bash
# Agent Zero SecureClaw - Cognitive File Integrity Check
# Detects tampering in agent's core files

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASELINE_DIR="${SCRIPT_DIR}/../.baselines"

# Files to monitor
FILES=(
    "/a0/SKILL.md"
    "/a0/prompts/default/agent.system.md"
    "/a0/prompts/default/agent.tools.md"
)

mkdir -p "$BASELINE_DIR"

echo "Agent Zero SecureClaw - Integrity Check"
echo "========================================"

# First run - create baselines
if [[ ! -f "${BASELINE_DIR}/SKILL.md.sha256" ]]; then
    echo "Creating baselines..."
    for file in "${FILES[@]}"; do
        if [[ -f "$file" ]]; then
            sha256sum "$file" > "${BASELINE_DIR}/$(basename "$file").sha256"
            echo "Created baseline for: $file"
        fi
    done
    echo "Baselines created. Run again to check for tampering."
    exit 0
fi

# Check for --rebaseline flag
if [[ "${1:-}" == "--rebaseline" ]]; then
    echo "Re-baselining files..."
    for file in "${FILES[@]}"; do
        if [[ -f "$file" ]]; then
            sha256sum "$file" > "${BASELINE_DIR}/$(basename "$file").sha256"
            echo "Updated baseline for: $file"
        fi
    done
    echo "Re-baselining complete."
    exit 0
fi

# Check integrity
TAMPERED=0
for file in "${FILES[@]}"; do
    baseline="${BASELINE_DIR}/$(basename "$file").sha256"
    if [[ -f "$file" && -f "$baseline" ]]; then
        CURRENT_HASH=$(sha256sum "$file" | awk '{print $1}')
        EXPECTED_HASH=$(awk '{print $1}' "$baseline")
        if [[ "$CURRENT_HASH" != "$EXPECTED_HASH" ]]; then
            echo "⚠️  TAMPERING DETECTED: $file"
            echo "   Expected: ${EXPECTED_HASH:0:16}..."
            echo "   Current:  ${CURRENT_HASH:0:16}..."
            TAMPERED=1
        else
            echo "✓ $file - OK"
        fi
    elif [[ -f "$baseline" && ! -f "$file" ]]; then
        echo "⚠️  FILE DELETED: $file (baseline exists)"
        TAMPERED=1
    fi
done

if [[ $TAMPERED -eq 1 ]]; then
    echo ""
    echo "⚠️  INTEGRITY VIOLATION DETECTED"
    echo "Your agent may be compromised. Review changes immediately."
    exit 2
else
    echo ""
    echo "✓ All files intact"
    exit 0
fi
