#!/usr/bin/env bash
# ==============================================================================
# MASWE-0002: Terminal Proof-of-Concept & External Storage Leak Audit
#
# Usage: bash features/maswe0002/poc/adb_verify.sh
# Needs: adb in PATH and a connected emulator with com.hasantuncay.mobsec
#        installed. Open the app and run the MASWE-0002 vectors first.
# ==============================================================================
set -uo pipefail

TARGET_PKG="com.hasantuncay.mobsec"
EXTERNAL_PATH="/sdcard/Android/data/$TARGET_PKG/files"

echo "======================================================================"
echo " [MASWE-0002] External Storage & Key Leakage Verification (adb)"
echo "======================================================================"

if ! command -v adb >/dev/null 2>&1; then
    echo "[-] adb was not found in PATH."
    exit 1
fi

if ! adb devices 2>/dev/null | grep -q "device"; then
    echo "[-] No device or emulator connected. Start one and retry."
    exit 1
fi

LISTING=$(adb shell "ls -la $EXTERNAL_PATH 2>/dev/null" || true)
if [ -z "$LISTING" ]; then
    echo "[-] Cannot read $EXTERNAL_PATH."
    echo "    The folder appears with the app's first write, and some images"
    echo "    restrict it for the shell user. Try 'adb root' on a non-Play image."
    echo "    Then open the app and run at least vector 1 (and vector 3 for the key)."
    exit 1
fi

echo "[*] External files directory: $EXTERNAL_PATH"
printf '%s\n' "$LISTING"

echo
echo "[*] Reading the plaintext record (vector 1)..."
PLAINTEXT=$(adb shell "cat $EXTERNAL_PATH/maswe0002_plaintext.json 2>/dev/null" || true)
TOKEN=$(printf '%s' "$PLAINTEXT" | grep -o '"auth_token": "[^"]*"' | head -n 1 || true)
PAN=$(printf '%s' "$PLAINTEXT" | grep -o '"pan": "[^"]*"' | head -n 1 || true)

echo "[*] Reading the stored key (vector 3)..."
KEY_BYTES=$(adb shell "od -An -tx1 $EXTERNAL_PATH/maswe0002_secret.key 2>/dev/null" || true)

KEY_ENC_HIT=$(printf '%s' "$LISTING" | grep -c "maswe0002_key_on_fs.enc" || true)
HARDCODED_HIT=$(printf '%s' "$LISTING" | grep -c "maswe0002_hardcoded.enc" || true)
WEAK_HIT=$(printf '%s' "$LISTING" | grep -c "maswe0002_weak.enc" || true)
REUSED_HIT=$(printf '%s' "$LISTING" | grep -c "maswe0002_reused_key.enc" || true)

FOUND=0
if [ -n "$TOKEN" ] || [ -n "$PAN" ] || [ -n "$KEY_BYTES" ] || [ "$KEY_ENC_HIT" != "0" ]; then
    FOUND=1
fi

echo
if [ "$FOUND" = "1" ]; then
    echo -e "\033[91m[!] CRITICAL VULNERABILITY CONFIRMED (MASWE-0002 / CWE-732):\033[0m"
    if [ -n "$TOKEN" ] || [ -n "$PAN" ]; then
        echo "    - Plaintext record readable without root or run-as:"
        [ -n "$TOKEN" ] && echo "      $TOKEN"
        [ -n "$PAN" ] && echo "      $PAN"
    fi
    if [ -n "$KEY_BYTES" ]; then
        echo "    - AES key readable beside its ciphertext (maswe0002_secret.key):"
        printf '%s\n' "$KEY_BYTES" | head -n 2
    fi
    [ "$KEY_ENC_HIT" != "0" ] && echo "    - maswe0002_key_on_fs.enc encrypts data with a key stored in the same folder"
    [ "$HARDCODED_HIT" != "0" ] && echo "    - maswe0002_hardcoded.enc uses a key embedded in the app"
    [ "$WEAK_HIT" != "0" ] && echo "    - maswe0002_weak.enc uses DES with a guessable key"
    [ "$REUSED_HIT" != "0" ] && echo "    - maswe0002_reused_key.enc derives its key from a device value, not a secret"
    echo
    echo "[*] Sensitive data sits in shared storage. Any shell user, root, or"
    echo "    forensic copy reads it without fighting the sandbox."
    exit 0
else
    echo "[✓] No MASWE-0002 artifacts found yet."
    echo "    Open the app, run the MASWE-0002 vectors (at least 1 and 3), then"
    echo "    run this script again."
    exit 1
fi
