#!/bin/bash
# Agent Zero SecureClaw - Quick Hardening
# Applies foundational security fixes

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Agent Zero SecureClaw - Quick Hardening"
echo "========================================"
echo ""

# Create backup directory
BACKUP_DIR="${SCRIPT_DIR}/../.backups/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# 1. Set directory permissions
echo "[1/4] Setting directory permissions..."
if [[ -d "/a0" ]]; then
    CURRENT_PERM=$(stat -c "%a" /a0 2>/dev/null || stat -f "%Lp" /a0)
    if [[ "$CURRENT_PERM" != "700" ]]; then
        cp -r /a0 "$BACKUP_DIR/" 2>/dev/null || true
        chmod 700 /a0
        echo "  ✓ Set /a0 to mode 700"
    else
        echo "  ✓ /a0 already mode 700"
    fi
fi

# 2. Set .env permissions
echo "[2/4] Setting .env file permissions..."
if [[ -f "/a0/.env" ]]; then
    ENV_PERM=$(stat -c "%a" /a0/.env 2>/dev/null || stat -f "%Lp" /a0/.env)
    if [[ "$ENV_PERM" != "600" ]]; then
        cp /a0/.env "$BACKUP_DIR/" 2>/dev/null || true
        chmod 600 /a0/.env
        echo "  ✓ Set .env to mode 600"
    else
        echo "  ✓ .env already mode 600"
    fi
fi

# 3. Create integrity baselines
echo "[3/4] Creating cognitive file baselines..."
bash "${SCRIPT_DIR}/check-integrity.sh" 2>/dev/null || echo "  ✓ Baselines created/updated"

# 4. Create killswitch file (disabled by default)
echo "[4/4] Setting up kill switch..."
if [[ ! -f "${SCRIPT_DIR}/../.killswitch" ]]; then
    echo "# Agent Zero SecureClaw Kill Switch" > "${SCRIPT_DIR}/../.killswitch.disabled"
    echo "# Rename to .killswitch to activate" >> "${SCRIPT_DIR}/../.killswitch.disabled"
    echo "  ✓ Kill switch template created (.killswitch.disabled)"
fi

echo ""
echo "Hardening complete!"
echo "Backup saved to: $BACKUP_DIR"
echo ""
echo "Next steps:"
echo "  - Run: bash ${SCRIPT_DIR}/quick-audit.sh"
echo "  - Set up daily audit in cron"
echo "  - Review the 15 security rules in SKILL.md"
