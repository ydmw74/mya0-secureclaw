#!/bin/bash
# Agent Zero SecureClaw - Emergency Response
# Comprehensive incident response for suspected compromise

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${SCRIPT_DIR}/../.events.log"

echo "=========================================="
echo "AGENT ZERO SECURECLAW EMERGENCY RESPONSE"
echo "=========================================="
echo "Started: $(date -u +"%Y-%m-%d %H:%M:%S UTC")"
echo ""

mkdir -p "${SCRIPT_DIR}/../.events"

# 1. Run integrity check
echo "[1/6] Running cognitive file integrity check..."
bash "${SCRIPT_DIR}/check-integrity.sh" 2>/dev/null || echo "  ⚠️  Integrity check failed"

# 2. Check for recent file modifications
echo ""
echo "[2/6] Files modified in last 30 minutes..."
find /a0 -type f -mmin -30 2>/dev/null | head -20 || echo "  (none found)"

# 3. Check for suspicious processes
echo ""
echo "[3/6] Checking for suspicious processes..."
ps aux | grep -E "(curl.*\|.*sh|wget.*\|.*bash|nc\s+-|ncat)" | grep -v grep || echo "  ✓ No suspicious processes"

# 4. Run full audit
echo ""
echo "[4/6] Running full security audit..."
bash "${SCRIPT_DIR}/quick-audit.sh" 2>/dev/null || echo "  ⚠️  Audit found issues"

# 5. Log the incident
echo ""
echo "[5/6] Logging incident..."
echo "[$(date -u +"%Y-%m-%d %H:%M:%S")] EMERGENCY_RESPONSE triggered" >> "$LOG_FILE"

# 6. Recommendations
echo ""
echo "[6/6] EMERGENCY RESPONSE COMPLETE"
echo ""
echo "=========================================="
echo "IMMEDIATE ACTIONS REQUIRED:"
echo "=========================================="
echo ""
echo "1. STOP all agent operations if not already stopped"
echo "2. Review /a0/prompts/default/agent.system.md for unauthorized changes"
echo "3. Check session logs for unusual activity"
echo "4. Rotate all API keys and credentials"
echo "5. Review installed skills: bash ${SCRIPT_DIR}/scan-skills.sh"
echo "6. Verify no unauthorized network connections"
echo ""
echo "Log saved to: $LOG_FILE"
echo ""
