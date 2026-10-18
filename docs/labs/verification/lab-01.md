# Verification: Lab 01 (Insecure Private Storage)

Run this checklist on a clean emulator before the lab is marked **✅ Ready** in the labs index. This file is for the proofing run only and is not part of the site navigation.

Note: this lab needs the app running for two vector taps. The inspection itself uses `run-as` (debug build), so no root is needed.

## Environment

| Field | Value |
|---|---|
| Date | |
| Emulator | ☐ Android Studio AVD ☐ Genymotion ☐ other: |
| Image / API level | |
| Host OS | |
| Terminal | ☐ Git Bash ☐ zsh ☐ PowerShell ☐ other: |
| App build | ☐ trainer APK ☐ built from source (`:app-vulnerable:assembleDebug`) |
| Project repository on this machine? | ☐ yes (run step 9) ☐ no (skip step 9) |
| Lab 00 re-run first? | ☐ yes |

## Steps

| # | Action | Expected | Result |
|---|---|---|---|
| 1 | `adb devices` | emulator listed as `device` | ☐ pass ☐ fail: |
| 2 | `adb shell run-as com.hasantuncay.mobsec ls -la files` and `... ls -la files/datastore` (before tap) | short listing; `datastore` usually `No such file or directory`. Record the exact shape | ☐ pass ☐ fail: |
| 3 | In app: expand `MASVS-STORAGE`, open `MASWE-0001`, confirm title bar `MASWE-0001 (VULNERABLE)`. Record the dashboard subtitle wording | screen opens; subtitle mismatch (says SECURE) is present and the note covers it | ☐ pass ☐ fail: |
| 4 | Tap `1. Data Stored Unencrypted (Cleartext)`, then repeat step 2 | `files/datastore/maswe0001_v1.preferences_pb` (+ lock file) now listed | ☐ pass ☐ fail: |
| 5 | `adb exec-out run-as com.hasantuncay.mobsec cat files/datastore/maswe0001_v1.preferences_pb \| grep -a eyJ` | one line with `auth_token` and a value starting `eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9`, ending in three dots | ☐ pass ☐ fail: |
| 6 | Tap `3. Encryption Key Stored on Filesystem`, then `ls -la files` and `ls -la shared_prefs` | `maswe0001_v3.enc` in files; `maswe0001_v3_keys.xml` in shared_prefs | ☐ pass ☐ fail: |
| 7 | `adb shell "run-as com.hasantuncay.mobsec cat shared_prefs/maswe0001_v3_keys.xml"` | XML with `<string name="aes_key">` and a base64 value | ☐ pass ☐ fail: |
| 8 | Repeat step 5 without `grep` (plain cat) | raw protobuf bytes appear around the token; note how ugly this is on the tester's terminal | ☐ pass ☐ fail: |
| 9 | (repo only) `bash features/maswe0001/poc/adb_verify.sh` from repo root | `[!] CRITICAL VULNERABILITY CONFIRMED (MASWE-0001 / CWE-312):` with the token and key lines; exit code 0. Also run it before tapping anything once to see the empty-state message | ☐ pass ☐ fail: |
| 10 | Screenshots 1 and 2 | token readable; key file shown | ☐ pass ☐ fail: |
| 11 | A colleague follows the page without questions | no missing preconditions; both taps easy to find | ☐ pass ☐ fail: |

## Observations for the lab page

Record anything that differs from the page, including labels, wording, ordering, terminal output, and timing:

- Step 2 before-tap output: did `files` exist right after install? Was `datastore` missing?
- Step 5: did `grep -a` print cleanly in Git Bash, or did protobuf bytes make the line hard to read? Did the match need a few seconds after the tap?
- Step 5: did the value really end with three dots?
- Step 6: how quickly did the files appear after the tap?
- Step 7: exact XML shape (encoding line, indentation) for the expected-output text.
- Did the dashboard subtitle really read `MASWE-0001: Private Storage (SECURE)`?
- Did any result card text accidentally reveal more than the lab assumes (paths, file names)?
- Step 9 script: printed lines, exit behavior. If it reported nothing after both taps, stop and fix the script before shipping.
- Anything that confused the run:

## Verdict

- ☐ All steps passed on a clean run. Set Lab 01 to **✅ Ready** in `docs/labs/index.md` and date this file.
- ☐ Differences found. Update the lab page, re-run the affected steps, then record the second run.
- ☐ Blocked by the app itself. Mark **⚠️ Known issue** in the index, note the blocker here, and open a repo issue.
