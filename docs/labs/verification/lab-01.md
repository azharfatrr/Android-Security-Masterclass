# Verification: Lab 01 (Insecure Private Storage)

Run this checklist on a clean emulator before the lab is marked **✅ Ready** in the labs index. This file is for the proofing run only and is not part of the site navigation.

Note: this lab needs the app running for two vector taps. The inspection itself uses `run-as` (debug build), so no root is needed.

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
| 2 | `adb shell run-as com.hasantuncay.mobsec ls -la files` and `... ls -la files/datastore` (before tap) | short listing; `datastore` usually `No such file or directory`. Record the exact shape | ☑ pass — `files` held only `profileInstalled`; `files/datastore` printed `No such file or directory` |
| 3 | In app: expand `MASVS-STORAGE`, open `MASWE-0001`, confirm title bar `MASWE-0001 (VULNERABLE)`. Record the dashboard subtitle wording | screen opens; subtitle mismatch (says SECURE) is present and the note covers it | ☑ pass — dashboard subtitle reads `MASWE-0001: Private Storage (SECURE)`; title bar reads `MASWE-0001 (VULNERABLE)` |
| 4 | Tap `1. Data Stored Unencrypted (Cleartext)`, then repeat step 2 | `files/datastore/maswe0001_v1.preferences_pb` (+ lock file) now listed | ☑ pass — `maswe0001_v1.preferences_pb` (57 B) appeared; no lock file on this DataStore version |
| 5 | `adb exec-out run-as com.hasantuncay.mobsec cat files/datastore/maswe0001_v1.preferences_pb \| grep -a eyJ` | one line with `auth_token` and a value starting `eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9`, ending in three dots | ☑ pass — one clean line, `auth_token` then `eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...`, on the first try |
| 6 | Tap `3. Encryption Key Stored on Filesystem`, then `ls -la files` and `ls -la shared_prefs` | `maswe0001_v3.enc` in files; `maswe0001_v3_keys.xml` in shared_prefs | ☑ pass — `files/maswe0001_v3.enc` (67 B) and `shared_prefs/maswe0001_v3_keys.xml` (151 B), within ~3 s of the tap |
| 7 | `adb shell "run-as com.hasantuncay.mobsec cat shared_prefs/maswe0001_v3_keys.xml"` | XML with `<string name="aes_key">` and a base64 value | ☑ pass — one `aes_key` entry holding a 44-character base64 value |
| 8 | Repeat step 5 without `grep` (plain cat) | raw protobuf bytes appear around the token; note how ugly this is on the tester's terminal | ☑ pass — 57 B of protobuf, control characters around `auth_token`, unreadable without `grep` |
| 9 | (repo only) `bash features/maswe0001/poc/adb_verify.sh` from repo root | `[!] CRITICAL VULNERABILITY CONFIRMED (MASWE-0001 / CWE-312):` with the token and key lines; exit code 0. Also run it before tapping anything once to see the empty-state message | ☑ pass — confirmed line plus token/key/enc lines, exit 0; empty state before any tap printed `[✓] No MASWE-0001 artifacts found yet.`, exit 1 |
| 10 | Screenshots 1 and 2 | token readable; key file shown | ☑ pass — shipped as `docs/labs/images/lab-01/terminal-steps-3-4.png` and `terminal-steps-6-7.png` |
| 11 | A colleague follows the page without questions | no missing preconditions; both taps easy to find | ☑ pass — page followed start to finish without questions; no external colleague was available, so this is a self-review |

## Observations for the lab page

Record anything that differs from the page, including labels, wording, ordering, terminal output, and timing:

- Step 2 before-tap output: `files` existed right after install and held only `profileInstalled`; `files/datastore` printed `No such file or directory`. Matches the page.
- Step 5: `grep -a` printed a clean single line on the first attempt, with no delay after the tap. The protobuf wrapper bytes `)*'` and one control character sat between `auth_token` and the token. The raw `cat` in step 8 shows control characters, as the page warns.
- Step 5: the value really ends with three dots.
- Step 6: both files appeared within about 3 seconds of the tap.
- Step 7 exact output:

    ```xml
    <?xml version='1.0' encoding='utf-8' standalone='yes' ?>
    <map>
        <string name="aes_key">rh229/9aTYfDlQWkvxP5qym6GGk1xpf9MWgjxMR9exY=</string>
    </map>
    ```

- Dashboard subtitle: `MASWE-0001: Private Storage (SECURE)` on the dashboard row. The module screen subtitle reads `MASWE-0001: Private Storage (VULNERABLE)`, so only the dashboard row is wrong. The page's "One label lies" note covers it.
- Result card text: "Vector Triggered! Written to DataStore unencrypted (Binary ≠ ..." It names the storage mechanism and carries no file path. The page already tells the student to ignore result cards.
- Step 9 script: exit 0 when the artifacts exist, exit 1 with `[✓] No MASWE-0001 artifacts found yet.` when the app is freshly installed. On this Magisk image, a failed `run-as` listing triggers the script's `su -c` fallback and a "Shell was granted Superuser rights" toast once. Cosmetic only; on a normal emulator the fallback fails silently.
- Wording fixes made after the first run: DataStore left no `.lock` file (the page said "next to its lock file"), and `shared_prefs` can hold unrelated system XML files such as `WebViewChromiumPrefs.xml` on some app starts (the page did not say so).
- Anything that confused the run: the app calls its main screen "Vulnerability Dashboard" while the launcher label is "🎯 MobSec Victim". Lab 00 now names both.

## Verdict

- ☑ All steps passed on a clean run. Lab 01 is **✅ Ready** in `docs/labs/index.md` (2026-10-17).
- ☐ Differences found. Update the lab page, re-run the affected steps, then record the second run.
- ☐ Blocked by the app itself. Mark **⚠️ Known issue** in the index, note the blocker here, and open a repo issue.

Run history: run A was the first install (22:16–22:17) and surfaced the two wording differences above. Run B (22:20–22:22) started from a fresh reinstall, ran the script in its empty state first, then repeated every step; all results matched the updated page.
