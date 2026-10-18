#!/usr/bin/env bash
# ==============================================================================
# MASWE-0001: Terminal Proof-of-Concept & Private Storage Leak Audit
#
# Usage: bash features/maswe0001/poc/adb_verify.sh
# Needs: adb in PATH and a connected emulator with com.hasantuncay.mobsec
#        installed (debug build). Open the app once and run the MASWE-0001
#        vulnerability vectors before running this script.
# ==============================================================================
set -uo pipefail

TARGET_PKG="com.hasantuncay.mobsec"

echo "======================================================================"
echo " [MASWE-0001] Unencrypted Private Storage Verification (adb)"
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

echo "[*] Listing shared_prefs, files, datastore, and cache:"
LISTING=$(app_exec "ls -la shared_prefs; ls -la files; ls -la files/datastore; ls -la cache" || true)
if [ -z "$LISTING" ]; then
    echo "[-] Could not read the app's private storage."
    echo "    Install the debug build of $TARGET_PKG, or run this on a rooted device."
    exit 1
fi
printf '%s\n' "$LISTING"

echo
echo "[*] Checking for unencrypted sensitive data..."

TOKEN_BLOB=$(app_exec "cat files/datastore/maswe0001_v1.preferences_pb 2>/dev/null" || true) 2>/dev/null
TOKEN_VALUE=$(printf '%s' "$TOKEN_BLOB" | grep -a -o 'eyJ[A-Za-z0-9._-]*' | head -n 1 || true)

KEYS_XML=$(app_exec "cat shared_prefs/maswe0001_v3_keys.xml 2>/dev/null" || true)
AES_KEY_LINE=$(printf '%s' "$KEYS_XML" | grep -o 'name="aes_key">[^<]*' | head -n 1 || true)

V5_XML=$(app_exec "cat shared_prefs/maswe0001_v5_sensitive.xml 2>/dev/null" || true)
V5_HIT=$(printf '%s' "$V5_XML" | grep -c 'auth_token' || true)

CACHE_LIST=$(app_exec "ls cache 2>/dev/null" || true)
CACHE_HIT=$(printf '%s' "$CACHE_LIST" | grep -c 'sensitive_temp_' || true)

FILES_LIST=$(app_exec "ls files 2>/dev/null" || true)
V3_ENC_HIT=$(printf '%s' "$FILES_LIST" | grep -c 'maswe0001_v3.enc' || true)

FOUND=0
if [ -n "$TOKEN_VALUE" ] || [ -n "$AES_KEY_LINE" ] || [ "$V5_HIT" != "0" ] || [ "$CACHE_HIT" != "0" ] || [ "$V3_ENC_HIT" != "0" ]; then
    FOUND=1
fi

echo
if [ "$FOUND" = "1" ]; then
    echo -e "\033[91m[!] CRITICAL VULNERABILITY CONFIRMED (MASWE-0001 / CWE-312):\033[0m"
    if [ -n "$TOKEN_VALUE" ]; then
        echo "    - Unencrypted token in files/datastore/maswe0001_v1.preferences_pb:"
        echo "      $TOKEN_VALUE"
    fi
    if [ -n "$AES_KEY_LINE" ]; then
        echo "    - AES key stored in cleartext (shared_prefs/maswe0001_v3_keys.xml):"
        echo "      $AES_KEY_LINE"
    fi
    if [ "$V3_ENC_HIT" != "0" ]; then
        echo "    - files/maswe0001_v3.enc holds data encrypted with that stored key"
    fi
    if [ "$V5_HIT" != "0" ]; then
        echo "    - shared_prefs/maswe0001_v5_sensitive.xml also holds a cleartext token"
    fi
    if [ "$CACHE_HIT" != "0" ]; then
        echo "    - cache/ keeps a sensitive session dump that is never deleted"
    fi
    echo
    echo "[*] Sensitive data sits unencrypted in private storage. Anyone with"
    echo "    root, a forensic image, or a debuggable build reads it as-is."
    exit 0
else
    echo "[✓] No MASWE-0001 artifacts found yet."
    echo "    Open the app, run the MASWE-0001 vectors (at least 1 and 3), then"
    echo "    run this script again."
    exit 1
fi
