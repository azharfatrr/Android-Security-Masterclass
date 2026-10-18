# Lab 06: The Backup That Took Everything

| | |
|---|---|
| **Module** | [MASWE-0006: Sensitive Data Not Excluded From Backup](../maswe/MASVS-STORAGE/maswe_006/MASWE-0006-Sensitive-Data-Backup.md) |
| **Category** | MASVS-STORAGE |
| **CWE** | CWE-200: Exposure of Sensitive Information to an Unauthorized Actor |
| **Time** | ~30 minutes |
| **Level** | Beginner |
| **Needs** | [Lab rules](index.md#before-you-conduct-any-lab) read · [Lab 00: Setup](setup.md) complete · **🎯 MobSec Victim** installed · `adb` working |

!!! info "Self-paced lab"
    Modern phones move app data on their own: to the user's cloud on a schedule, to a new phone during migration, and, where the platform still allows it, to a laptop over `adb backup`. This app said yes to all of it and excluded nothing. Your job is to prove both halves from the device: the settings that allow it, and the sensitive files that are in scope. Section E tells you exactly what to capture as proof.

---

## A · Mission

Backups are the quietest data channel on a phone. The user never opens an app to make one, and the data leaves without the app being asked. One manifest switch decides whether an app's data is in scope, and a list of rules decides what gets excluded. This app turned the switch on and left the exclusion list empty.

Prove that from your terminal: first read the platform's own record of the switch. Then make the app write a few files, find them in the locations backups cover, and read what is inside. Card data, session keys, and an email address are all in there, in the clear.

Do not read the project source code. Use the installed app and your terminal.

---

## B · Steps

Run everything in one terminal (Git Bash on Windows). The app's result cards repeat what the demo was built to say; ignore them and build your evidence from your own commands.

### 1. Read the switch before you touch the app

Android tracks whether an app is in scope for backup as a flag on the installed package:

```bash
adb shell dumpsys package com.hasantuncay.mobsec | grep -i ALLOW_BACKUP
```

Expected: one line of the form `flags=[ HAS_CODE ALLOW_CLEAR_USER_DATA ALLOW_BACKUP ... ]` inside the package's dump. The other flags vary by build; the token `ALLOW_BACKUP` is the part that matters here. No app interaction is needed to see it.

### 2. Open the module

Open **🎯 MobSec Victim**, expand `MASVS-STORAGE`, and open the `MASWE-0006` row.

!!! note "One label lies"
    The row subtitle reads `MASWE-0006: Secure Implementation`. That is a bug in this training build. The screen title bar is what counts: `MASWE-0006 (VULNERABLE)`.

### 3. The file the ADB backup vector leaves

Tap the second button: `2. ADB Local Backup (adb backup)`. Then find what it wrote:

```bash
adb shell run-as com.hasantuncay.mobsec ls -la files
adb exec-out run-as com.hasantuncay.mobsec cat files/maswe0006_local_backup_vault.db
```

Expected: a new file `maswe0006_local_backup_vault.db`, and inside it one line reading `SQLITE_SIMULATION: PAN=`, a 16-digit card number, a pipe character, then `CVV: ` and three digits.

!!! tip "The names promise more than the files are"
    Despite the `.db` name, the file is not a SQLite database. It is one line of plain text. Do not try to open it in a database browser; `cat` tells you everything.

### 4. The file the migration vector leaves

Tap the third button: `3. Device-to-Device Migration`. Then:

```bash
adb exec-out run-as com.hasantuncay.mobsec cat files/maswe0006_migration_credentials.json
```

Expected: a JSON object with two keys. `refreshToken` holds a base64 value, and `masterKey` holds a value starting with `0x`. Phone migration is meant to move a user's life to a new device; it should not move this.

### 5. The file the cloud backup vector leaves

Tap the first button: `1. Auto Backup — No Exclusion Rules`. This one writes to preferences, so list that folder first:

```bash
adb shell run-as com.hasantuncay.mobsec ls -la shared_prefs
adb shell "run-as com.hasantuncay.mobsec cat shared_prefs/maswe0006_cloud_backup_session.xml"
```

Expected: a file named `maswe0006_cloud_backup_session.xml` with two entries, `auth_token` (the JWT-looking value again) and `user_email`, a personal email address in plain text. The write is asynchronous, so if the entry is missing, wait a second and read again.

### 6. Try the extraction the vector is named after

This is the step where the platform gets a vote. Ask it to pack the app's data into a backup archive:

```bash
adb backup -f maswe0006_loot.ab -noapk com.hasantuncay.mobsec
```

A dialog appears on the emulator asking to back up your data. Confirm it (no password needed). Two outcomes are normal:

- **An archive appears.** Check it with `ls -l maswe0006_loot.ab`. The first bytes are readable: `head -c 24 maswe0006_loot.ab` prints `ANDROID BACKUP`, which is the format's magic string. You now hold the app's data on your laptop.
- **The platform refuses.** On many Android 12 and newer images, `adb backup` answers `Backup disabled` or returns an empty file. That refusal is the platform's default hardening, not your mistake. Note the exact message and move on; the finding from steps 1 through 5 does not depend on this archive.

### 7. Optional: let the project's checker confirm it

If you have the project repository on this machine, the module ships a script that repeats the flag check and all four file reads:

```bash
bash features/maswe0006/poc/adb_verify.sh
```

Expected: `[!] CRITICAL VULNERABILITY CONFIRMED (MASWE-0006 / CWE-200):` followed by the backup flag line, the card data line, the session keys line, and a note about the token and email in preferences. The script confirms files from vectors 1, 2, and 4, so the report can list more than the three you created.

---

## C · Look & tell

Answer these in your notes before moving on:

1. ✍️ The `dumpsys` flag is a setting, not a file. With that switch on and no exclusion rules, list the channels this app's data can travel through without the app ever running again.
2. ✍️ Two files are named `.db` and `.sqlite`, and a result card promised a database browser would open them. What is really inside, based on your own output?
3. ✍️ A backup is made by the user and belongs to the user. Explain why that is not a reason to keep card data out of the archive.

---

## D · Prove it

You have the finding when all four are true:

| Test | What it shows |
|---|---|
| The step 1 output | The platform has the app flagged as backup-eligible, with no special handling visible in the dump |
| The steps 3 to 5 outputs | Card data, session keys, and a personal email sit in plaintext inside `files/` and `shared_prefs/`, the standard backup scope |
| The step 6 outcome | Either a real archive with `ANDROID BACKUP` in its header, or the platform's refusal; record which, and note that the finding survives either way |
| Section C, questions 1 to 3 | Your explanation of the channels and the impact |

If you ran step 7, its output is a second, independent confirmation of the same artifacts. Attach it as well.

---

## E · Your evidence

Hand in:

1. 📷 Screenshot 1: the step 1 `ALLOW_BACKUP` line, plus the file listing from step 3.
2. 📷 Screenshot 2: the card data line from step 3 and at least one more file read (step 4 or 5).
3. 📷 Screenshot 3 (only if your image produced an archive): `ls -l` and the `ANDROID BACKUP` header.
4. ✍️ Two or three sentences, in your own words:
   - which switch is on and which rules are missing,
   - which sensitive files are in the backup scope,
   - one concrete way an attacker reaches a backup that the user never noticed.

Submit these through your training channel. No long report is needed.

---

## F · Stuck?

??? question "Hint 1: the dumpsys grep prints nothing"
    - Older images label the field `pkgFlags=`. Try `adb shell dumpsys package com.hasantuncay.mobsec | grep -i flags` and read the lines.
    - If there is no output at all, confirm the app is installed: `adb shell pm list packages | grep mobsec`.
    - Reading the flag needs no root and no app interaction. If it fails, the package name is wrong.

??? question "Hint 2: a file is missing or the folder looks different"
    - Vector 1 writes preferences asynchronously; wait a second and list again.
    - `shared_prefs` and `files` also hold other modules' artifacts. Look for the exact names: `maswe0006_cloud_backup_session.xml`, `maswe0006_local_backup_vault.db`, `maswe0006_migration_credentials.json`, `maswe0006_unencrypted_customer_records.sqlite`.
    - `run-as: package not debuggable` means the release build is installed. Reinstall the debug APK from Lab 00.

??? question "Hint 3: the adb backup step misbehaves"
    - The on-device dialog must be confirmed. If no dialog appears, the image has the backup service disabled; that is the refusal case described in step 6.
    - If you got an archive and want to look inside, this trick often works in Git Bash:
      `( printf "\x1f\x8b\x08\x00\x00\x00\x00\x00" ; tail -c +25 maswe0006_loot.ab ) | tar -ztvf - | head -n 30`
      It may print warnings; what you are hunting for is your app's file names. If nothing lists, the archive header and size remain your evidence.
    - Never delete the archive as "useless"; it is evidence of the channel, even when the platform refuses to make one.

---

## G · Reveal

!!! warning "Open only after sections C and E are done"
    Your screenshots are the evidence, not this section. Read it last.

??? question "What you actually found"
    This is **MASWE-0006**, covering **CWE-200** (information exposure) with **CWE-312** roots.

    The manifest declares `android:allowBackup="true"` and points at the stock AOSP rule files, `backup_rules.xml` and `data_extraction_rules.xml`, with every include and exclude entry still commented out. Net effect: everything the app writes into `files/`, `shared_prefs/`, and its databases is in scope for cloud Auto Backup and device-to-device transfer, and `dumpsys` confirmed the flag on your emulator.

    The artifacts prove the second half. `maswe0006_local_backup_vault.db` holds `PAN=...|CVV=...` as a plain text line. `maswe0006_migration_credentials.json` holds a refresh token and a master key. `maswe0006_cloud_backup_session.xml` holds a bearer token and a personal email in preferences. A fourth vector (`4. Sensitive Data Unencrypted in Backup`) writes a customer record with a plaintext password to `maswe0006_unencrypted_customer_records.sqlite`.

    Why it matters:

    - Cloud Auto Backup runs without the app's involvement. A compromised cloud account can leak app data with no device access at all.
    - Device-to-device transfer clones credentials to a new phone, a channel that rarely gets the scrutiny of an app review.
    - `adb backup` on an attached laptop turns any unlocked workstation into an extraction point. Android 12 and newer narrow this path for normal apps (targetSdk 31 and up), which is exactly why the flag and rules are the real fix.
    - Card data in any of these channels means a compliance finding, not just a security one; PCI-DSS treats storage and backup together.

    What the secure app does instead:

    The `:app-secure` manifest sets `android:allowBackup="false"`, its rule files exclude the sensitive entries explicitly, and the module's secure repository pre-encrypts its data with AES-256-GCM before it goes anywhere near a backup scope.

    Go deeper:

    - Reference page: [MASWE-0006: Sensitive Data Not Excluded From Backup](../maswe/MASVS-STORAGE/maswe_006/MASWE-0006-Sensitive-Data-Backup.md)
    - The vulnerable code lives in `features/maswe0006/src/main/java/com/hasantuncay/mobsec/maswe0006/vulnerable/Maswe0006VulnerableRepository.kt`.
    - The module's automation is in `features/maswe0006/poc/`: a Semgrep rule pack for CI, a Frida hook for runtime inspection, and the `adb` script from step 7.
