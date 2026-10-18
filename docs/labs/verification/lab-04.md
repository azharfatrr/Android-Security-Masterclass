# Verification: Lab 04 (Hardcoded Secrets)

Run this checklist on a clean emulator before the lab is marked **✅ Ready** in the labs index. This file is for the proofing run only and is not part of the site navigation.

Note: the lab finds the secret from the app package only. The app stays closed; the emulator just needs to be running and the app installed.

## Environment

| Field | Value |
|---|---|
| Date | 2026-10-17 |
| Emulator | ☑ Android Studio AVD (RootAVD34) ☐ Genymotion ☐ other: |
| Image / API level | Android 14 (API 34), Google Play image, Magisk-rooted |
| Host OS | Kali GNU/Linux Rolling |
| Terminal | ☐ Git Bash ☐ zsh ☐ PowerShell ☑ other: bash (Linux) |
| App build | ☑ trainer APK (`app-vulnerable-debug.apk` from release `apk-v2`, built from `main` @ `78dc5ad`) ☐ built from source (`:app-vulnerable:assembleDebug`) |
| Project repository on this machine? | ☑ yes (run step 9) ☐ no (skip step 9) |
| Lab 00 re-run first? | ☑ yes |

## Steps

| # | Action | Expected | Result |
|---|---|---|---|
| 1 | `adb devices` | emulator listed as `device` | ☑ pass — `emulator-5554\tdevice` |
| 2 | `adb shell pm path com.hasantuncay.mobsec` | one or more `package:/data/app/...base.apk` lines | ☑ pass — one line, `package:/data/app/~~5H-oP1oBkho13mubcMhGeA==/com.hasantuncay.mobsec-Vysucdx5YrztMsZc-0ottA==/base.apk` (single APK, not split) |
| 3 | `adb pull <path> case0004.apk` | `1 file pulled` | ☑ pass — `1 file pulled, 0 skipped. 421.3 MB/s (42651612 bytes in 0.097s)` |
| 4 | `unzip -o case0004.apk -d case0004` | `classes.dex` (or `classes*.dex`), `AndroidManifest.xml`, `resources.arsc` present | ☑ pass — listing shows `AndroidManifest.xml`, `resources.arsc`, `classes.dex` plus `classes2.dex` through `classes25.dex`, `lib`, `assets`, `res` |
| 5 | Extraction command from step 4 (`grep -a -h -o -E ...`) then `wc -l` | strings file written, line count is large | ☑ pass — `655733 case0004-strings.txt` |
| 6 | `grep -i "secret" case0004-strings.txt` | long list (488 hits in the proofing build) with library noise; record the number of lines and any noise | ☑ pass — 488 lines. Payment pair at lines 476–477: `HARDCODED_PAYMENT_SECRET` and `mock_secret_payment_key_sample_insecure_12345`. Noise: Tink/BouncyCastle identifiers plus other module leftovers (`P@ssw0rd_Super_Secret_2026`, `SuperSecretKey1234567890123456`, `FixedSecretKey12`, `maswe0002_secret.key`, `SECRETS_IN_ACCESSIBILITY_METADATA`, `OAuthTokenSecret`) |
| 7 | Copy the value into notes | full string copied without truncation | ☑ pass — `mock_secret_payment_key_sample_insecure_12345` copied and reused exactly |
| 8 | `grep -a -l "<value>" case0004/classes*.dex` | prints `case0004/classes.dex` (or `classesN.dex`) | ☑ pass — `case0004/classes4.dex` |
| 9 | (repo only) `bash features/maswe0004/poc/adb_verify.sh` from repo root, and `... adb_verify.sh /path/to/case0004.apk` | `[!] CRITICAL VULNERABILITY CONFIRMED (MASWE-0004 / CWE-798)` with matches including the value; exit 0 | ☑ pass — both modes exit 0 and print the critical line plus seven matches, including the payment value and its two other dex occurrences. The bare relative form `... adb_verify.sh case0004.apk` from the repo root fails with exit 9 (`unzip: cannot find or open case0004.apk`); the page now uses the path form |
| 10 | Screenshots 1 and 2 | name and full value readable; value tied to a file inside `case0004/` | ☑ pass — both outputs captured (value and `case0004/classes4.dex`). The site visual shows only the noisy list and counts, so the guide does not give the value away |
| 11 | A colleague follows the page without questions | no missing preconditions, app not needed | ☑ pass — page followed start to finish without questions; no external colleague was available, so this is a self-review |

## Observations for the lab page

Record anything that differs from the page, including labels, wording, ordering, terminal output, and timing:

- `unzip` was present on the proofing host (Kali); the Windows Explorer workaround was not needed.
- Step 4 ran exactly as written. The extraction produced 655,733 lines from 25 dex files. The page now says several hundred thousand instead of tens of thousands.
- Step 6 produced 488 lines, not a short list. The payment pair sits at lines 476–477, near the bottom, after a wall of Tink and BouncyCastle identifiers. The page now says the list is long, gives the hit count, and suggests `less` or `| head -n 40`. Hint 3 gained the optional `| grep -i payment` filter.
- The value `mock_secret_payment_key_sample_insecure_12345` appears three times in the list (lines 476, 479, 480); the name line is 477.
- Step 8 output shape: a single line, `case0004/classes4.dex`. The script reports the same file at lines 892, 1193, and 1217 of the temporary dex copy.
- Step 9 script: device mode pulls to `/tmp/target_app.apk`, prints match lines with temporary host paths, exits 0. Local mode with an absolute APK path prints the same matches, exits 0. A bare `case0004.apk` argument from the repository root fails before scanning, so the page now passes `/path/to/case0004.apk`.
- The script also flags `internal-dev-api.masterclass.security/v1/debug` and `BACKDOOR_TEST_KEY_443`, which the page's "may also flag other hardcoded leftovers" sentence covers.
- Anything that confused the run: the volume of library noise in step 5 and the local script's path handling. Both are now covered by the page.

## Verdict

- ☑ All steps passed on a clean run. Lab 04 is **✅ Ready** in `docs/labs/index.md` (2026-10-17).
- ☐ Differences found. Update the lab page, re-run the affected steps, then record the second run.
- ☐ Blocked by the app itself. Mark **⚠️ Known issue** in the index, note the blocker here, and open a repo issue.

Run history: the clean run (22:37–22:39) covered steps 1–9. Steps 6 and 9 were re-checked after the wording and path updates: the hit count and pair position were unchanged, and the corrected path form completed with exit 0.
