#!/usr/bin/env bash
# ==============================================================================
# MASWE-0007: Terminal Proof-of-Concept & Cryptographic Verification
#
# Usage: bash features/maswe0007/poc/adb_verify.sh
# Needs: adb in PATH and a connected emulator with com.hasantuncay.mobsec
#        installed. Open the app and run the MASWE-0007 vectors (at least
#        1, 2, 4, and 7) before running this script.
# ==============================================================================
set -uo pipefail

TAG="MASWE_0007"

echo "======================================================================"
echo " [MASWE-0007] Improper Encryption Verification (adb)"
echo "======================================================================"

if ! command -v adb >/dev/null 2>&1; then
    echo "[-] adb was not found in PATH."
    exit 1
fi

if ! adb devices 2>/dev/null | grep -q "device"; then
    echo "[-] No device or emulator connected. Start one and retry."
    exit 1
fi

echo "[*] Scanning logcat for the module's cryptographic output..."
LOGS=$(adb logcat -d -s "$TAG" 2>/dev/null | tr -d '\r' || true)

get_line() { printf '%s' "$LOGS" | grep -a "$1" | tail -n 1 || true; }

DES_LINE=$(get_line "Vector 1:")
IV_LINE=$(get_line "Vector 2:")
PAD_LINE=$(get_line "Vector 3:")
ECB_LINE=$(get_line "Vector 4:")
KEY_LINE=$(get_line "Vector 5:")
RSA_LINE=$(get_line "Vector 6:")
XOR_LINE=$(get_line "Vector 7:")

# Reverse the vector 7 "encryption": Base64 decode, then XOR every byte with 0x5A.
RECOVERED=""
if [ -n "$XOR_LINE" ]; then
    B64=$(printf '%s' "$XOR_LINE" | sed 's/.*Base64 string: //')
    if [ -n "$B64" ]; then
        RECOVERED=$(printf '%s' "$B64" | base64 -d 2>/dev/null | od -An -tu1 | tr ' ' '\n' | grep . | while read -r b; do printf "\\x$(printf '%02x' $((b ^ 0x5A)))"; done || true)
    fi
fi

FOUND=0
if [ -n "$DES_LINE" ] || [ -n "$IV_LINE" ] || [ -n "$PAD_LINE" ] || [ -n "$ECB_LINE" ] || [ -n "$KEY_LINE" ] || [ -n "$RSA_LINE" ] || [ -n "$XOR_LINE" ]; then
    FOUND=1
fi

echo
if [ "$FOUND" = "1" ]; then
    echo -e "\033[91m[!] CRITICAL VULNERABILITY CONFIRMED (MASWE-0007 / CWE-327):\033[0m"
    if [ -n "$DES_LINE" ]; then
        echo "    - Obsolete DES with a static 8-character key:"
        echo "      $DES_LINE"
    fi
    if [ -n "$IV_LINE" ]; then
        echo "    - AES-CBC with a hardcoded all-zero IV (deterministic output):"
        echo "      $IV_LINE"
    fi
    if [ -n "$ECB_LINE" ]; then
        echo "    - ECB mode leaking equal ciphertext blocks:"
        echo "      $ECB_LINE"
    fi
    if [ -n "$RECOVERED" ]; then
        echo "    - XOR/Base64 'encryption' reversed without any key:"
        echo "      recovered plaintext: $RECOVERED"
    fi
    if [ -n "$PAD_LINE" ] || [ -n "$KEY_LINE" ] || [ -n "$RSA_LINE" ]; then
        echo "    - Also captured: unauthenticated CBC (vector 3), 56/64-bit DES key (vector 5),"
        echo "      RSA key reuse (vector 6)."
    fi
    echo
    echo "[*] Every key here lives inside the app binary, and every ciphertext"
    echo "    above sits in the system log."
    exit 0
else
    echo "[✓] No MASWE-0007 artifacts found yet."
    echo "    Open the app, run the MASWE-0007 vectors (at least 1, 2, 4, and 7),"
    echo "    then run this script again."
    exit 1
fi
