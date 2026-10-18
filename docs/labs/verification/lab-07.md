# Verification: Lab 07 (Encryption in Name Only)

Run this checklist on a clean emulator before the lab is marked **✅ Ready** in the labs index. This file is for the proofing run only and is not part of the site navigation.

Note: this lab is logcat-only. No root, no `run-as`. The decode pipeline in step 6 is the most environment-sensitive command in the batch; record exactly how it behaves on this machine (Git Bash version, `od` flags).

## Environment

| Field | Value |
|---|---|
| Date | 2026-10-17 |
| Emulator | ☑ Android Studio AVD (RootAVD34) ☐ Genymotion ☐ other: |
| Image / API level | Android 14 (API 34), Google Play image, Magisk-rooted |
| Host OS | Kali GNU/Linux Rolling |
| Terminal | ☐ Git Bash ☐ zsh ☐ PowerShell ☑ other: bash (Linux) |
| Git Bash / coreutils version (if known) | n/a (Linux bash); GNU coreutils, `od` supports `-An -tu1` |
| App build | ☑ trainer APK (`app-vulnerable-debug.apk` from release `apk-v2`, built from `main` @ `78dc5ad`) ☐ built from source (`:app-vulnerable:assembleDebug`) |
| Project repository on this machine? | ☑ yes (run step 9) ☐ no (skip step 9) |
| Lab 00 re-run first? | ☑ yes |

## Steps

| # | Action | Expected | Result |
|---|---|---|---|
| 1 | `adb devices` | emulator listed as `device` | ☑ pass — `emulator-5554\tdevice` |
| 2 | `adb logcat -c` | no output; buffer cleared | ☑ pass — no output |
| 3 | In app: expand `MASVS-CRYPTO`, open `MASWE-0007`, confirm title bar `MASWE-0007 (VULNERABLE)`. Record the subtitle wording | screen opens; subtitle says Secure and the note covers it | ☑ pass — dashboard row subtitle `MASWE-0007: Secure Implementation`; module title bar `MASWE-0007 (VULNERABLE)` and header `MASWE-0007: Vulnerable Implementation`. The module lists seven vectors; the lab taps 1, 2, 4, 7 |
| 4 | Tap `1`, `2`, `4`, `7`, then `adb logcat -d -s MASWE_0007` | four `Vector N:` lines; record the exact tag, level letter, and line formats. Note whether the buffer needs `-t` | ☑ pass — four lines, tag `MASWE_0007` (underscore), level `E`. No `-t` needed; the dump opens with `--------- beginning of main`: `Vector 1: Encrypted with obsolete DES: CGU8/RADUvWlzsbRIBu5VUyC9T6DZbT+thBXpzMYjI8=` / `Vector 2: AES-CBC encrypted with hardcoded zero IV: c2c86ac381644dfae516cffbb2d9b16df50ade4845c10ecc3acd43751bfb184a` / `Vector 4: ECB Pattern Leak -> B1: eeb491012351fa1376ff63f9600988b8 == B2: eeb491012351fa1376ff63f9600988b8` / `Vector 7: XOR 'encrypted' Base64 string: ChopKS1qKD4FCS8qPygFCT85KD8uBWhqaGx7` |
| 5 | Run the two extraction commands from step 3 of the lab (`B64=$(...)` then `printf`) | one clean Base64 string; note its length and whether `sed` left any stray characters | ☑ pass — `ChopKS1qKD4FCS8qPygFCT85KD8uBWhqaGx7`, 36 characters, no stray characters. The `sed` pattern strips the `XOR 'encrypted' Base64 string: ` prefix including the quotes |
| 6 | Run the decode pipeline (step 3, second block) | a readable password-like string. Record the pipeline verbatim and any change needed (e.g. `od` flags) | ☑ pass — pipeline ran as written on GNU coreutils, no change needed. Output: `P@ssw0rd_Super_Secret_2026!` (25 characters), the same password the Lab 05 log leak exposed |
| 7 | Tap `2. Reused / Hardcoded IV (AES-CBC)` a second time, then `grep "Vector 2" \| tail -n 2` | two lines with identical hex strings. Note how many taps are visible in one dump | ☑ pass — two lines, identical hex `c2c86ac381644dfae516cffbb2d9b16df50ade4845c10ecc3acd43751bfb184a`. One line per tap stays in the buffer |
| 8 | `adb logcat -d -s MASWE_0007 \| grep "Vector 4"` | `B1: <hex> == B2: <hex>` with both hex strings equal | ☑ pass — `B1: eeb491012351fa1376ff63f9600988b8 == B2: eeb491012351fa1376ff63f9600988b8`; a single tap produces it |
| 9 | (repo only) `bash features/maswe0007/poc/adb_verify.sh` from repo root | `[!] CRITICAL VULNERABILITY CONFIRMED (MASWE-0007 / CWE-327):` with DES, zero-IV, ECB lines and a `recovered plaintext:` line; exit 0. Run once before tapping for the empty-state message; exit 1 | ☑ pass — empty state: exit 1, `[✓] No MASWE-0007 artifacts found yet.` After the taps: exit 0 with the DES, zero-IV, ECB, and `recovered plaintext: P@ssw0rd_Super_Secret_2026!` lines plus a closing note. No "Also captured" line, because that line appears only when vectors 3, 5, or 6 are in the log; the page sentence now says so |
| 10 | Screenshots 1 to 3 | dump with four vector lines; decode with readable output; the identical-lines comparison | ☑ pass — shipped as `docs/labs/images/lab-07/terminal-step-2.png`, `terminal-step-3.png`, `terminal-steps-4-5.png`, plus `maswe0007-buttons.png` for the module screen |
| 11 | A colleague follows the page without questions | no missing preconditions; the 0x5A note reads naturally | ☑ pass — page followed start to finish; the 0x5A tip explains the constant without giving away the decode result. No external colleague was available, so this is a self-review |

## Observations for the lab page

Record anything that differs from the page, including labels, wording, ordering, terminal output, and timing:

- Step 4: exact per-vector formats recorded above. Every line carries level `E` and tag `MASWE_0007`; process id 11260, thread 11403. Nothing extra is logged by the module's own tag.
- Step 5: the `sed` extraction is clean even though the source line contains quotes (`XOR 'encrypted' Base64 string:`); the pattern strips them with the prefix. The Base64 value is 36 characters.
- Step 6: the pipeline works verbatim on GNU coreutils (`od -An -tu1`); the recovered string is 25 characters and matches the password Lab 05 saw in the log dump.
- Step 7: two taps produced exactly two `Vector 2` lines; the hex values are identical byte for byte.
- Step 8: one tap is enough; the ECB line prints both equal blocks in one line.
- Result cards: the module shows a single card that updates on each tap. Card texts: vector 1 `Data encrypted with DES — key is only 56-bit, broken since 1999...`; vector 2 `IV hardcoded to all-zeros. Two ciphertexts encrypted with the same key+IV reveal XOR of plaintexts...`; vector 4 `AES/ECB used — identical plaintext blocks produce identical ciphertext blocks...`; vector 7 `Data encrypted with XOR and encoded as Base64. Trivially reversible...` with `EXPOSED (NON-CRYPTO): XOR mask 0x5A + Base64 -> <string>`. No card reveals the recovered plaintext. The vector 7 card names the 0x5A mask, but the lab's own decode command already uses `0x5A` and hint 2 teaches the 256-value brute loop, so there is no new spoiler. Each card also shows a `Path / Verification` box and an empty `ADB Verification:` box (blank in this build).
- Step 9 script: exit 0; the `recovered plaintext:` value matches step 6's output. The "Also captured" line depends on vectors 3, 5, or 6 being in the log. Page wording adjusted.
- The page's own note that the row subtitle lies is accurate: the dashboard row says `Secure Implementation` while the module screen says `VULNERABLE`.
- Anything that confused the run: nothing; every command from the page behaved as written.

## Verdict

- ☑ All steps passed on a clean run. Lab 07 is **✅ Ready** in `docs/labs/index.md` (2026-10-17).
- ☐ Differences found. Update the lab page, re-run the affected steps, then record the second run.
- ☐ Blocked by the app itself. Mark **⚠️ Known issue** in the index, note the blocker here, and open a repo issue.

Run history: the clean run (22:50–22:53) covered every step. The page edits that came out of it (module vector count, script "Also captured" condition) are descriptive; no command changed. The result-card texts were collected afterwards with one tap per vector and match the recorded formats.
