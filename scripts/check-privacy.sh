#!/bin/bash
# Agent Zero SecureClaw - Privacy Checker
# Scans text for PII before public posting

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="${SCRIPT_DIR}/../configs/privacy-rules.json"

# Get text from argument or stdin
if [[ $# -gt 0 ]]; then
    TEXT="$1"
else
    TEXT=$(cat)
fi

PII_FOUND=0

echo "Privacy Check Results"
echo "====================="

# Check API keys
if echo "$TEXT" | grep -qE "(sk-ant-|sk-proj-|xoxb-|xoxp-|ghp_|gho_|AKIA)[A-Za-z0-9_-]+"; then
    echo "❌ CRITICAL: API key/token detected"
    PII_FOUND=1
fi

# Check IP addresses
if echo "$TEXT" | grep -qE "\b[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\b"; then
    echo "❌ CRITICAL: IP address detected"
    PII_FOUND=1
fi

# Check internal paths
if echo "$TEXT" | grep -qE "~/\.[a-zA-Z]+/"; then
    echo "❌ HIGH: Internal path detected"
    PII_FOUND=1
fi

# Check for human names (simple pattern)
if echo "$TEXT" | grep -qE "my human [A-Z][a-z]+"; then
    echo "❌ HIGH: Human name detected"
    PII_FOUND=1
fi

# Check for location info
if echo "$TEXT" | grep -qE "(live[sd]? in|based in|located in|from) [A-Z]"; then
    echo "⚠️  MEDIUM: Location information detected"
    PII_FOUND=1
fi

# Check for device names
if echo "$TEXT" | grep -qiE "(pixel|iphone|macbook|mac mini|thinkpad|galaxy|surface)"; then
    echo "⚠️  MEDIUM: Device name detected"
    PII_FOUND=1
fi

# Check for VPN/network tools
if echo "$TEXT" | grep -qiE "(tailscale|wireguard|zerotier|cloudflare tunnel|ngrok)"; then
    echo "⚠️  MEDIUM: Network tool detected"
    PII_FOUND=1
fi

if [[ $PII_FOUND -eq 0 ]]; then
    echo "✓ No PII detected"
    echo ""
    echo "Remember: Could a hostile stranger use this to identify your human?"
    exit 0
else
    echo ""
    echo "⚠️  PII detected! Review and rewrite before posting."
    echo "Rule: Never reveal name, location, employer, devices, routines, family, religion, health, finances, or infrastructure."
    exit 1
fi
