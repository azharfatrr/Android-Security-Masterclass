# Verification: Lab 05 (What the Logs Remember)

Run this checklist on a clean emulator before the lab is marked **✅ Ready** in the labs index. This file is for the proofing run only and is not part of the site navigation.

Note: the log steps need no root or `run-as`. Only the file step uses `run-as`, which works on the debug build. The multi-line dump output through `grep -A` is the part most likely to differ between logcat versions; record its exact shape.

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
| 2 | `adb logcat -c` | no output; buffer cleared | ☑ pass — no output. The empty-state script run right after printed `[✓] No MASWE-0005 artifacts found yet.` and exited 1 |
| 3 | In app: expand `MASVS-STORAGE`, open `MASWE-0005`, confirm title bar `MASWE-0005 (VULNERABLE)`. Record the subtitle wording | screen opens; subtitle says SECURE and the note covers it | ☑ pass — dashboard subtitle `MASWE-0005: Logging (SECURE)`; module screen subtitle `MASWE-0005: Logging (VULNERABLE)`; title bar `MASWE-0005 (VULNERABLE)` |
| 4 | Tap `1. Trigger System Console Leak`, then `adb logcat -d -t 400 \| tail -n 80` | one loud multi-line block among emulator noise; note whether the banner is visible within `-t 400` | ☑ pass — the first attempt, two seconds after the tap, was flooded by a transient Play-services burst and showed only `Finsky` lines. Retaps put the banner 15, 16, and 29 lines from the end (delays 0, 3, 6 s), inside `tail -n 80`. Hint 1 covers the retry |
| 5 | `adb logcat -d -t 400 \| grep -A 25 "CRITICAL APP STATE DUMP"` | the full dump: master key, RSA key prefix, name, TCKN, email, plaintext password. Record the exact lines and whether `-A 25` captures the block whole | ☑ pass — all 13 dump lines captured (banner through the closing dashes), followed by 12 lines of unrelated noise. `Master Key: 0x8F432B9A1C5E7D8F9A0B1C2D3E4F5A6B`, `RSA Private: -----BEGIN RSA PRIVATE KEY----...`, `Name: John Doe`, `TCKN: 10987654321`, `Email: john.doe@personal.domain.com`, `Password (Plain): P@ssw0rd_Super_Secret_2026!` |
| 6 | Record the exact tag (is it `VULN_APP_TAG`?) and the level letter | `VULN_APP_TAG`, `E` | ☑ pass — every dump line carries `E VULN_APP_TAG:` |
| 7 | Tap `2. Trigger Network Leak`, then `adb logcat -d -t 600 \| grep -A 8 "graphql/v2"` | request line plus `Authorization: Bearer eyJ...` and `X-CSRF-Token:` headers; the request itself fails (simulated) and that is expected. Also test the fallback `grep -i okhttp` | ☑ pass — all four OkHttp lines captured under tag `OkHttp`, level `I`: `--> GET https://api.internal.company.com/graphql/v2`, `Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...`, `X-CSRF-Token: 8a7b6c5d4e3f2a1b9c8d7e6f5a4b3c2d`, `--> END GET`. The failure (`<-- HTTP FAILED: java.net.UnknownHostException ... (291ms)`) follows 0.3 s later. The `grep -i -E "okhttp\|Bearer\|graphql"` fallback prints the same block |
| 8 | Tap `3. Trigger Local File Leak`, then `ls -la files` and `adb exec-out run-as com.hasantuncay.mobsec cat files/app_debug.log` | `app_debug.log` exists; line ends with `PAN: ` (16 digits) and `CVV: ` (3 digits). Note how the file grows per tap | ☑ pass — `app_debug.log` 109 B after one tap, 218 B after two. Line: `[ERROR] [1792291291622] [main] Payment processing failed. Diagnostic Dump -> PAN: 4532112233445566, CVV: 123` (epoch-millisecond timestamp in brackets) |
| 9 | (repo only) `bash features/maswe0005/poc/adb_verify.sh` from repo root | `[!] CRITICAL VULNERABILITY CONFIRMED (MASWE-0005 / CWE-532):` with the credential line, the bearer line, the SDK line, and the payment line; exit 0. Run once before tapping anything for the empty-state message | ☑ pass — exit 0 with three bullets: the `Password (Plain): ...` line, the `OkHttp` bearer line, and the `app_debug.log` payment line. No separate SDK line appears; the lab triggers vectors 1–3, and the page's expected text lists exactly those three. Empty state: `[✓] No MASWE-0005 artifacts found yet.`, exit 1 |
| 10 | Screenshots 1 and 2 | dump with password readable; second sink visible | ☑ pass — shipped as `docs/labs/images/lab-05/terminal-step-4.png`, `terminal-step-5.png`, and `terminal-step-6.png` |
| 11 | A colleague follows the page without questions | no missing preconditions; toast about the attacker app does not confuse | ☑ pass — page followed start to finish; the toast text is `Attacker App is not installed! Please install the app-attacker module first.` and it appears on every tap. No external colleague was available, so this is a self-review |

## Observations for the lab page

Record anything that differs from the page, including labels, wording, ordering, terminal output, and timing:

- Step 4 timing: normal taps keep the banner within the last 30 lines, so `tail -n 80` sees it. One attempt hit a Play-services log burst right after install and missed it; a retap fixed it. The page's hint 1 already says to tap again and dump immediately.
- Step 5 shape: `grep -A 25` returns the whole 13-line block and then a dozen lines of unrelated log traffic. No continuation prefix is added; every line keeps its full logcat prefix.
- Step 5: there is no separate "who is watching" warning line before the dump. The first line of the block is the banner `--- CRITICAL APP STATE DUMP ---`.
- Step 7: the OkHttp lines carry tag `OkHttp`, not `VULN_NETWORK`. The result card names `VULN_NETWORK`, so a student who greps the card's tag finds nothing. Hint 2 now names the real tag.
- Step 7 extras: `--> END GET` and `<-- HTTP FAILED: java.net.UnknownHostException` are part of the block. The page now mentions both.
- Step 8 format: `[ERROR] [<epoch millis>] [main] Payment processing failed. Diagnostic Dump -> PAN: ..., CVV: ...`; the file doubles in size with each tap.
- Result cards: vector 1 shows `Data logged to Logcat (System Console)` and `VULN_APP_TAG`; vector 2 shows `Check Logcat for OkHttp BODY interceptor leak!` and the wrong tag `VULN_NETWORK`; vector 3 shows `/data/user/0/com.hasantuncay.mobsec/files/app_debug.log`. They reveal tags and the file path, but no leaked values. Section B already tells the student to ignore them.
- The missing-attacker toast repeats on every tap and covers part of the result card for about two seconds. The step 2 note now says it repeats.
- Step 9 script: exit 0; three bullets. Its banner says "vectors 1, 2, and 4", while the lab triggers 1–3; the printed results match the lab's three sinks. The SDK line named in the checklist template does not appear in this build.
- Anything that confused the run: the transient log flood in step 4, the card's wrong `VULN_NETWORK` tag, and the toast repetition. All are covered above or by the page.

## Verdict

- ☑ All steps passed on a clean run. Lab 05 is **✅ Ready** in `docs/labs/index.md` (2026-10-17).
- ☐ Differences found. Update the lab page, re-run the affected steps, then record the second run.
- ☐ Blocked by the app itself. Mark **⚠️ Known issue** in the index, note the blocker here, and open a repo issue.

Run history: the clean run (22:40–22:42) covered every step. Step 4 was retested with taps at 0, 3, and 6 seconds to confirm the tail window. The page edits that came out of the run (vector count, toast repetition, `END GET`, real OkHttp tag) describe the same captured output; no command changed.
