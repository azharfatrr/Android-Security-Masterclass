# Verification: Lab 07 (Encryption in Name Only)

Run this checklist on a clean emulator before the lab is marked **✅ Ready** in the labs index. This file is for the proofing run only and is not part of the site navigation.

Note: this lab is logcat-only. No root, no `run-as`. The decode pipeline in step 6 is the most environment-sensitive command in the batch; record exactly how it behaves on this machine (Git Bash version, `od` flags).

## Environment

| Field | Value |
|---|---|
| Date | |
| Emulator | ☐ Android Studio AVD ☐ Genymotion ☐ other: |
| Image / API level | |
| Host OS | |
| Terminal | ☐ Git Bash ☐ zsh ☐ PowerShell ☐ other: |
| Git Bash / coreutils version (if known) | |
| App build | ☐ trainer APK ☐ built from source (`:app-vulnerable:assembleDebug`) |
| Project repository on this machine? | ☐ yes (run step 9) ☐ no (skip step 9) |
| Lab 00 re-run first? | ☐ yes |

## Steps

| # | Action | Expected | Result |
|---|---|---|---|
| 1 | `adb devices` | emulator listed as `device` | ☐ pass ☐ fail: |
| 2 | `adb logcat -c` | no output; buffer cleared | ☐ pass ☐ fail: |
| 3 | In app: expand `MASVS-CRYPTO`, open `MASWE-0007`, confirm title bar `MASWE-0007 (VULNERABLE)`. Record the subtitle wording | screen opens; subtitle says Secure and the note covers it | ☐ pass ☐ fail: |
| 4 | Tap `1`, `2`, `4`, `7`, then `adb logcat -d -s MASWE_0007` | four `Vector N:` lines; record the exact tag, level letter, and line formats. Note whether the buffer needs `-t` | ☐ pass ☐ fail: |
| 5 | Run the two extraction commands from step 3 of the lab (`B64=$(...)` then `printf`) | one clean Base64 string; note its length and whether `sed` left any stray characters | ☐ pass ☐ fail: |
| 6 | Run the decode pipeline (step 3, second block) | a readable password-like string. Record the pipeline verbatim and any change needed (e.g. `od` flags) | ☐ pass ☐ fail: |
| 7 | Tap `2. Reused / Hardcoded IV (AES-CBC)` a second time, then `grep "Vector 2" \| tail -n 2` | two lines with identical hex strings. Note how many taps are visible in one dump | ☐ pass ☐ fail: |
| 8 | `adb logcat -d -s MASWE_0007 \| grep "Vector 4"` | `B1: <hex> == B2: <hex>` with both hex strings equal | ☐ pass ☐ fail: |
| 9 | (repo only) `bash features/maswe0007/poc/adb_verify.sh` from repo root | `[!] CRITICAL VULNERABILITY CONFIRMED (MASWE-0007 / CWE-327):` with DES, zero-IV, ECB lines and a `recovered plaintext:` line; exit 0. Run once before tapping for the empty-state message; exit 1 | ☐ pass ☐ fail: |
| 10 | Screenshots 1 to 3 | dump with four vector lines; decode with readable output; the identical-lines comparison | ☐ pass ☐ fail: |
| 11 | A colleague follows the page without questions | no missing preconditions; the 0x5A note reads naturally | ☐ pass ☐ fail: |

## Observations for the lab page

Record anything that differs from the page, including labels, wording, ordering, terminal output, and timing:

- Step 4: exact per-vector line formats; whether the level is `E`; anything extra the module logs.
- Step 5: whether `sed 's/.*Base64 string: //'` extracted cleanly on the real line (quotes around `encrypted` in the source line).
- Step 6: the pipeline as-run; recovered string length vs the password found elsewhere in training; any `od`/`tr`/`grep` tweak needed.
- Step 7: number of `Vector 2` lines visible after two taps; identical values confirmed.
- Step 8: exact line; also check whether a single tap is enough (it regenerates per tap).
- Result cards after taps 1, 2, 4, 7: does any card reveal `0x5A` or the recovered plaintext before the learner decodes? Record card text. The lab's tip explains 0x5A anyway; confirm consistency.
- Step 9 script: printed lines, exit codes, the `recovered plaintext:` value.
- Anything that confused the run:

## Verdict

- ☐ All steps passed on a clean run. Set Lab 07 to **✅ Ready** in `docs/labs/index.md` and date this file.
- ☐ Differences found. Update the lab page, re-run the affected steps, then record the second run.
- ☐ Blocked by the app itself. Mark **⚠️ Known issue** in the index, note the blocker here, and open a repo issue.
