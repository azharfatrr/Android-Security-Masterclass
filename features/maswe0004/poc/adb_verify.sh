#!/usr/bin/env bash
# ==============================================================================
# MASWE-0004: Terminal Proof-of-Concept & Secret Audit Verification
# ==============================================================================
set -euo pipefail

TARGET_PKG="com.hasantuncay.mobsec"
APK_PATH="${1:-}"

echo "======================================================================"
echo " [MASWE-0004] Hardcoded Secrets Verification & String Extraction"
echo "======================================================================"

if [ -z "$APK_PATH" ]; then
    echo "[*] Pulling installed APK from device for: $TARGET_PKG"
    DEVICE_PATH=$(adb shell pm path "$TARGET_PKG" 2>/dev/null | head -n 1 | cut -d':' -f2 | tr -d '\r' || true)
    if [ -z "$DEVICE_PATH" ]; then
        echo "[-] Target package $TARGET_PKG not found on connected device."
        echo "    Usage: ./adb_verify.sh [path/to/app-vulnerable-debug.apk]"
        exit 1
    fi
    APK_PATH="/tmp/target_app.apk"
    adb pull "$DEVICE_PATH" "$APK_PATH"
fi

echo "[*] Analyzing APK archive: $APK_PATH"
TEMP_DIR=$(mktemp -d)
unzip -q "$APK_PATH" -d "$TEMP_DIR"

echo "[*] Scanning DEX bytecode and strings for secret markers..."
# Common key formats plus the demo secret markers used by this module
FOUND_SECRETS=$(grep -rnEao "(sk_live_[0-9a-zA-Z]{24}|AKIA[0-9A-Z]{16}|AIza[0-9A-Za-z_-]{35}|mock_secret_[A-Za-z0-9_]+|BACKDOOR_TEST_KEY_[0-9]+|internal-dev-api\.[A-Za-z0-9./_-]+)" "$TEMP_DIR" || true)

if [ -n "$FOUND_SECRETS" ]; then
    echo -e "\033[91m[!] CRITICAL VULNERABILITY CONFIRMED (MASWE-0004 / CWE-798):\033[0m"
    echo "$FOUND_SECRETS"
else
    echo -e "\033[92m[✓] No cleartext static API keys detected in APK strings.\033[0m"
fi

rm -rf "$TEMP_DIR"
echo "======================================================================"
