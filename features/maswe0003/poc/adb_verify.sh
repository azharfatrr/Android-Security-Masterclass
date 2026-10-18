#!/usr/bin/env bash
# ==============================================================================
# MASWE-0003: Terminal Proof-of-Concept & Key Storage Leak Audit
#
# Usage: bash features/maswe0003/poc/adb_verify.sh
# Needs: adb in PATH and a connected emulator with com.hasantuncay.mobsec
#        installed (debug build). Open the app and run the MASWE-0003 vectors
#        (at least 1 and 3) before running this script.
# ==============================================================================
set -uo pipefail

TARGET_PKG="com.hasantuncay.mobsec"

echo "======================================================================"
echo " [MASWE-0003] Key Storage & Logcat Leak Verification (adb)"
echo "======================================================================"

if ! command -v adb >/dev/null 2>&1; then
    echo "[-] adb was not found in PATH."
    exit 1
fi

if ! adb devices 2>/dev/null | grep -q "device"; then
    echo "[-] No device or emulator connected. Start one and retry."
    exit 1
fi

# Run a command inside the app's private storage. Tries the app identity first
# (works on debug builds), then root, then a rooted adb shell.
app_exec() {
    local cmd="$1" out
    out=$(adb shell "run-as $TARGET_PKG sh -c '$cmd'" 2>/dev/null) && { printf '%s\n' "$out"; return 0; }
    out=$(adb shell "su -c 'cd /data/data/$TARGET_PKG && $cmd'" 2>/dev/null) && { printf '%s\n' "$out"; return 0; }
    out=$(adb shell "cd /data/data/$TARGET_PKG && $cmd" 2>/dev/null) && { printf '%s\n' "$out"; return 0; }
    return 1
}

b64decode() {
    base64 -d 2>/dev/null || base64 -D 2>/dev/null
}

echo "[*] Reading shared_prefs/crypto_key.xml (vector 1)..."
KEY_XML=$(app_exec "cat shared_prefs/crypto_key.xml 2>/dev/null" || true)
AES_B64=$(printf '%s' "$KEY_XML" | grep -o -E '[A-Za-z0-9+/]{40,}={0,2}' | head -n 1 || true)

RAW_LEN=""
if [ -n "$AES_B64" ]; then
    RAW_LEN=$(printf '%s' "$AES_B64" | b64decode | wc -c | tr -d ' ')
fi

echo "[*] Reading logcat for key import leaks (vector 3)..."
LOG_LINE=$(adb logcat -d -s MASWE_0003_KEY_IMPORT 2>/dev/null | grep "Importing key" | tail -n 1 | tr -d '\r' || true)

echo
FOUND=0
if [ -n "$AES_B64" ] || [ -n "$LOG_LINE" ]; then
    FOUND=1
fi

if [ "$FOUND" = "1" ]; then
    echo -e "\033[91m[!] CRITICAL VULNERABILITY CONFIRMED (MASWE-0003 / CWE-312):\033[0m"
    if [ -n "$AES_B64" ]; then
        echo "    - AES key stored in cleartext in shared_prefs/crypto_key.xml"
        if [ -n "$RAW_LEN" ]; then
            echo "      the stored value decodes to $RAW_LEN bytes of raw key material"
        else
            echo "      the stored value is readable base64 key material"
        fi
    fi
    if [ -n "$LOG_LINE" ]; then
        echo "    - Key material written to the system log:"
        echo "      $LOG_LINE"
    fi
    echo
    echo "[*] Key material lives outside the Android Keystore: in a preferences"
    echo "    file and in logcat, ready to copy."
    exit 0
else
    echo "[✓] No MASWE-0003 artifacts found yet."
    echo "    Open the app, run vectors 1 and 3, then run this script again."
    exit 1
fi
