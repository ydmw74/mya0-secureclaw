#!/bin/bash
# Agent Zero SecureClaw - Installation Script

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="/a0/usr/workdir/agent-zero-secureclaw"

echo "Agent Zero SecureClaw - Installation"
echo "====================================="
echo ""

# Check if running from correct location
if [[ "$SCRIPT_DIR" != "$INSTALL_DIR/scripts" ]]; then
    echo "Copying to installation directory..."
    mkdir -p "$INSTALL_DIR"
    cp -r "${SCRIPT_DIR}/.."/* "$INSTALL_DIR/"
    echo "  ✓ Copied to $INSTALL_DIR"
fi

# Set executable permissions
echo "Setting executable permissions..."
chmod +x "$INSTALL_DIR/scripts/"*.sh
echo "  ✓ Scripts are now executable"

# Create necessary directories
echo "Creating directories..."
mkdir -p "$INSTALL_DIR/.baselines"
mkdir -p "$INSTALL_DIR/.backups"
mkdir -p "$INSTALL_DIR/.events"
echo "  ✓ Directories created"

echo ""
echo "Installation complete!"
echo ""
echo "Next steps:"
echo "  1. Review SKILL.md for the 15 security rules"
echo "  2. Run: bash $INSTALL_DIR/scripts/quick-harden.sh"
echo "  3. Run: bash $INSTALL_DIR/scripts/quick-audit.sh"
echo ""
