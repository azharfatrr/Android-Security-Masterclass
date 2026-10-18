#!/usr/bin/env bash
# ==============================================================================
# MASWE-0005: Terminal Proof-of-Concept & Logging Leak Audit
#
# Usage: bash features/maswe0005/poc/adb_verify.sh
# Needs: adb in PATH and a connected emulator with com.hasantuncay.mobsec
#        installed (debug build). Open the app and run the MASWE-0005 vectors
#        (at least 1, 2, and 3) before running this script.
# ==============================================================================
set -uo pipefail

TARGET_PKG="com.hasantuncay.mobsec"

echo "======================================================================"
echo " [MASWE-0005] Sensitive Data Logging Verification (adb)"
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

log_tail() {
    adb logcat -d -t 4000 2>/dev/null | grep -a "$1" | tail -n 1 | tr -d '\r' || true
}

echo "[*] Scanning logcat for leaked credentials (vectors 1, 2, and 4)..."
DUMP_HIT=$(log_tail "CRITICAL APP STATE DUMP")
PASSWORD_HIT=$(log_tail "Password (Plain)")
BEARER_HIT=$(log_tail "Authorization: Bearer")
SDK_HIT=$(log_tail "Sending Crashlytics Payload")

echo "[*] Reading files/app_debug.log (vector 3)..."
FILE_LOG=$(app_exec "cat files/app_debug.log 2>/dev/null" || true)
PAY_HIT=$(printf '%s' "$FILE_LOG" | grep -a "Payment processing failed" | tail -n 1 | tr -d '\r' || true)

echo
FOUND=0
if [ -n "$DUMP_HIT" ] || [ -n "$PASSWORD_HIT" ] || [ -n "$BEARER_HIT" ] || [ -n "$SDK_HIT" ] || [ -n "$PAY_HIT" ]; then
    FOUND=1
fi

if [ "$FOUND" = "1" ]; then
    echo -e "\033[91m[!] CRITICAL VULNERABILITY CONFIRMED (MASWE-0005 / CWE-532):\033[0m"
    if [ -n "$PASSWORD_HIT" ]; then
        echo "    - Plaintext credential in the system log:"
        echo "      $PASSWORD_HIT"
    elif [ -n "$DUMP_HIT" ]; then
        echo "    - App state dump in the system log:"
        echo "      $DUMP_HIT"
    fi
    if [ -n "$BEARER_HIT" ]; then
        echo "    - Network logger printed request credentials:"
        echo "      $BEARER_HIT"
    fi
    if [ -n "$SDK_HIT" ]; then
        echo "    - Third-party SDK simulator logged a PII payload (email, clipboard, drafts):"
        echo "      $SDK_HIT"
    fi
    if [ -n "$PAY_HIT" ]; then
        echo "    - Card data persisted in files/app_debug.log (plaintext, never deleted):"
        echo "      $PAY_HIT"
    fi
    echo
    echo "[*] Sensitive values cross the app boundary through logs and log files."
    echo "    Bug reports, crash SDKs, and adb sessions all read these sinks."
    exit 0
else
    echo "[✓] No MASWE-0005 artifacts found yet."
    echo "    Open the app, run vectors 1, 2, and 3, then run this script again."
    exit 1
fi
