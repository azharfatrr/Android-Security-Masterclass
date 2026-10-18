#!/usr/bin/env bash
# ==============================================================================
# MASWE-0006: Terminal Proof-of-Concept & Backup Exposure Audit
#
# Usage: bash features/maswe0006/poc/adb_verify.sh
# Needs: adb in PATH and a connected emulator with com.hasantuncay.mobsec
#        installed (debug build). Open the app and run the MASWE-0006 vectors
#        (at least 1, 2, and 3) before running this script.
# ==============================================================================
set -uo pipefail

TARGET_PKG="com.hasantuncay.mobsec"

echo "======================================================================"
echo " [MASWE-0006] Backup Exposure & Sensitive Data Verification (adb)"
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

echo "[*] Checking the installed package's backup flags..."
BACKUP_FLAG=$(adb shell "dumpsys package $TARGET_PKG 2>/dev/null | grep -i ALLOW_BACKUP" | head -n 1 | tr -d '\r' || true)
if [ -n "$BACKUP_FLAG" ]; then
    echo "    $BACKUP_FLAG"
else
    echo "    [-] No ALLOW_BACKUP flag found for $TARGET_PKG. Is it installed?"
fi

echo
echo "[*] Reading the module's data files in backup scope..."
VAULT=$(app_exec "cat files/maswe0006_local_backup_vault.db 2>/dev/null" || true)
MIGRATION=$(app_exec "cat files/maswe0006_migration_credentials.json 2>/dev/null" || true)
RECORDS=$(app_exec "cat files/maswe0006_unencrypted_customer_records.sqlite 2>/dev/null" || true)
PREFS_XML=$(app_exec "cat shared_prefs/maswe0006_cloud_backup_session.xml 2>/dev/null" || true)

PAN_LINE=$(printf '%s' "$VAULT" | grep -a "PAN=" | tail -n 1 | tr -d '\r' || true)
MIG_LINE=$(printf '%s' "$MIGRATION" | grep -a "refreshToken" | tail -n 1 | tr -d '\r' || true)
REC_LINE=$(printf '%s' "$RECORDS" | grep -a "plain_pwd" | tail -n 1 | tr -d '\r' || true)
PREFS_HIT=$(printf '%s' "$PREFS_XML" | grep -c "auth_token" || true)

FOUND=0
if [ -n "$PAN_LINE" ] || [ -n "$MIG_LINE" ] || [ -n "$REC_LINE" ] || [ "$PREFS_HIT" != "0" ]; then
    FOUND=1
fi

echo
if [ "$FOUND" = "1" ]; then
    echo -e "\033[91m[!] CRITICAL VULNERABILITY CONFIRMED (MASWE-0006 / CWE-200):\033[0m"
    if [ -n "$BACKUP_FLAG" ]; then
        echo "    - Package is backup-enabled: ALLOW_BACKUP present in dumpsys flags"
    fi
    if [ -n "$PAN_LINE" ]; then
        echo "    - Card data in a backup-scope file (files/maswe0006_local_backup_vault.db):"
        echo "      $PAN_LINE"
    fi
    if [ -n "$MIG_LINE" ]; then
        echo "    - Session keys in a backup-scope file (files/maswe0006_migration_credentials.json):"
        echo "      $MIG_LINE"
    fi
    if [ -n "$REC_LINE" ]; then
        echo "    - Customer record with a plaintext password (files/maswe0006_unencrypted_customer_records.sqlite):"
        echo "      $REC_LINE"
    fi
    if [ "$PREFS_HIT" != "0" ]; then
        echo "    - Token and email in shared_prefs/maswe0006_cloud_backup_session.xml"
    fi
    echo
    echo "[*] With no exclusion rules, these files travel through cloud backup,"
    echo "    device-to-device transfer, and (where the platform still allows it)"
    echo "    adb backup."
    exit 0
else
    echo "[✓] No MASWE-0006 data artifacts found yet."
    if [ -n "$BACKUP_FLAG" ]; then
        echo "    Note: the backup flag is already set on the installed package."
    fi
    echo "    Open the app, run the MASWE-0006 vectors (at least 1, 2, and 3), then"
    echo "    run this script again."
    exit 1
fi
