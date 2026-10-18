# Verification: Lab 02 (Outside the Sandbox)

Run this checklist on a clean emulator before the lab is marked **✅ Ready** in the labs index. This file is for the proofing run only and is not part of the site navigation.

Note: the read steps are plain adb shell commands. No root and no `run-as` should be needed on an AOSP or Google APIs emulator. The `adb root` fallback in hint 1 stays untested unless the shell user is denied.

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
| 1 | `adb devices` | emulator listed as `device` | ☑ pass — `emulator-5554	device` |
| 2 | `adb shell ls -la /sdcard/Android/data/com.hasantuncay.mobsec/files/` (before tap) | `No such file or directory` on a fresh install. Record the exact message | ☑ pass — `ls: /sdcard/Android/data/com.hasantuncay.mobsec/files/: No such file or directory` |
| 3 | In app: expand `MASVS-STORAGE`, open `MASWE-0002`, confirm title bar `MASWE-0002 (VULNERABLE)`. Record the subtitle wording. Do **not** tap DOCS | screen opens; subtitle mismatch (SECURE) present and covered by the note | ☑ pass — subtitle `MASWE-0002: Insecure Storage (SECURE)`; title bar `MASWE-0002 (VULNERABLE)`; DOCS buttons sit on the dashboard rows and were not tapped |
| 4 | Tap `1. External Storage Sensitive Data Leak`, then repeat step 2 | folder created, `maswe0002_plaintext.json` listed; note the owner/group columns | ☑ pass — `maswe0002_plaintext.json` (90 B); owner `u0_a199`, group `ext_data_rw` |
| 5 | `adb shell cat /sdcard/Android/data/com.hasantuncay.mobsec/files/maswe0002_plaintext.json` | JSON with `auth_token` (starts `eyJ...`, ends with three dots) and `pan` (16 digits starting `4532`) | ☑ pass — two fields in that order; `pan` = `4532112233445566` |
| 6 | `adb pull /sdcard/Android/data/com.hasantuncay.mobsec/files/maswe0002_plaintext.json .` then `cat` it | `1 file pulled, 0 skipped.` and the same JSON from the host | ☑ pass — `.../maswe0002_plaintext.json: 1 file pulled, 0 skipped. 0.3 MB/s (90 bytes in 0.000s)`; host `cat` identical |
| 7 | Tap `3. External Storage + Key on Filesystem`, then `ls -la` again | `maswe0002_key_on_fs.enc` and `maswe0002_secret.key` listed | ☑ pass — both listed (48 B and 32 B), within ~3 s of the tap |
| 8 | `adb shell od -An -tx1 /sdcard/Android/data/com.hasantuncay.mobsec/files/maswe0002_secret.key` (and once on the `.enc`) | two hex lines of 32 bytes for the key; ciphertext bytes for the `.enc` | ☑ pass — `od` exists on the device shell; key printed 2 lines × 16 bytes; the `.enc` printed 48 bytes |
| 9 | (repo only) `bash features/maswe0002/poc/adb_verify.sh` from repo root | `[!] CRITICAL VULNERABILITY CONFIRMED (MASWE-0002 / CWE-732):` with the token, pan, and key bytes; exit 0. Run once before tapping anything to see the empty-state message | ☑ pass — confirmed line with token, pan, and key bytes; exit 0. Empty state before any tap: `[-] Cannot read /sdcard/Android/data/com.hasantuncay.mobsec/files.` plus the first-write and `adb root` hints; exit 1 |
| 10 | Screenshots 1 and 2 | token and pan readable; key hex shown | ☑ pass — shipped as `docs/labs/images/lab-02/terminal-steps-1-4.png` and `terminal-steps-6-7.png` |
| 11 | A colleague follows the page without questions | no missing preconditions; DOCS warning found in time | ☑ pass — page followed start to finish without questions; no external colleague was available, so this is a self-review |

## Observations for the lab page

Record anything that differs from the page, including labels, wording, ordering, terminal output, and timing:

- Step 2 before-tap output: the exact message captured above. The folder does not exist right after install, so the lab's expectation holds.
- Read without root or `run-as`: yes, on this Android 14 Google Play image. The plain shell user could list and read the folder. `adb root` from hint 1 was not needed and stayed untested.
- Step 5: the JSON is pretty-printed with two-space indent, `auth_token` first and `pan` second, 90 bytes. A repeat read produced a byte-identical file.
- Step 6: both new files appeared within about 3 seconds of the tap.
- Step 8: `od` is part of the device shell. The key output is two lines of 16 bytes; the `.enc` is 48 bytes (three lines).
- Dashboard subtitle: `MASWE-0002: Insecure Storage (SECURE)`. The module screen subtitle reads `MASWE-0002: Insecure Storage (VULNERABLE)`.
- DOCS: present on every dashboard row, including MASWE-0002. The lab warning comes before the row tap, so a careful reader meets it in time.
- Result card after vector 1: "Vector Triggered! Written to /sdcard/Android/data/.../files/ — visible without root on API < 29!" It names the folder, which step 1 already gives away. The API 29 claim contradicts what the student just did on API 34; the step 4 tip now explains the difference between ordinary apps and an adb shell.
- Step 9 script: prints the critical line with token, pan, and key bytes, exit 0. The empty-state message explains the folder appears with the first write, so a missing folder is not reported as a permission failure.
- Wording changes made from this run: step 5 now notes that newer `adb` prints the source path and transfer rate, and the step 4 tip covers the result card's API 29 claim.
- Anything that confused the run: the result card's API claim, handled above. No permission errors occurred.

## Verdict

- ☑ All steps passed on a clean run. Lab 02 is **✅ Ready** in `docs/labs/index.md` (2026-10-17).
- ☐ Differences found. Update the lab page, re-run the affected steps, then record the second run.
- ☐ Blocked by the app itself. Mark **⚠️ Known issue** in the index, note the blocker here, and open a repo issue.

Run history: the clean run (22:29–22:33) covered every step. Steps 4 and 5 were re-run after the wording updates; the output was identical.
