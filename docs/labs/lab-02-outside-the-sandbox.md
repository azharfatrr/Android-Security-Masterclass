# Lab 02: Outside the Sandbox

| | |
|---|---|
| **Module** | [MASWE-0002: Sensitive Data Stored Unencrypted Outside of Private Storage](../maswe/MASVS-STORAGE/maswe_002/MASWE-0002-Insecure-Storage.md) |
| **Category** | MASVS-STORAGE |
| **CWE** | CWE-732: Incorrect Permission Assignment for Critical Resource |
| **Time** | ~25 minutes |
| **Level** | Beginner |
| **Needs** | [Lab rules](index.md#before-you-conduct-any-lab) read · [Lab 00: Setup](setup.md) complete · **🎯 MobSec Victim** installed · `adb` working |

!!! info "Self-paced lab"
    The app writes the data when you tell it to; the finding is yours. This time you will not need root, `run-as`, or any special flag. One plain `adb shell` reads everything, and that is the point of the lab. Section E tells you exactly what to capture as proof.

---

## A · Mission

In Lab 01 the app kept its files in the private sandbox, and you had to step into the app's own identity to read them. This module writes to a different place: the app's slice of shared storage, the part of the device a PC can reach over USB.

A sensitive record is sitting there in plain text. Find it, read it, and copy it off the device with your own commands. You get no help beyond the emulator and adb, and you should need none.

Then find the second artifact: an encrypted file that stored its own key in the same folder, one name over.

Do not read the project source code. Use the installed app and your terminal.

---

## B · Steps

Run everything in one terminal (Git Bash on Windows) and one folder of your choice.

!!! warning "Do not tap the DOCS button"
    The dashboard row for this module carries a DOCS button that opens the official OWASP page for it. That page is the answer. Leave it alone until your evidence is captured.

### 1. Look before

```bash
adb shell ls -la /sdcard/Android/data/com.hasantuncay.mobsec/files/
```

Expected on a fresh install: `No such file or directory`. The folder is created together with the app's first write. `/sdcard` is an alias for `/storage/emulated/0`; both spellings work.

### 2. Make the app write outside its sandbox

Open **🎯 MobSec Victim**, expand `MASVS-STORAGE`, and open the `MASWE-0002` row.

!!! note "One label lies"
    The row subtitle may read `MASWE-0002: Insecure Storage (SECURE)`. That is a bug in this training build. The screen title bar is what counts: `MASWE-0002 (VULNERABLE)`.

The module lists five vectors. This lab needs the first and the third:

![The MASWE-0002 screen with its five vector buttons](images/lab-02/maswe0002-buttons.png){ width="380" }

Tap the first button: `1. External Storage Sensitive Data Leak`. Ignore the app's result card, and leave DOCS alone.

### 3. Look again

```bash
adb shell ls -la /sdcard/Android/data/com.hasantuncay.mobsec/files/
```

Expected: the folder now exists and lists one file, `maswe0002_plaintext.json`. Owner and size are whatever your emulator reports.

### 4. Read the record

```bash
adb shell cat /sdcard/Android/data/com.hasantuncay.mobsec/files/maswe0002_plaintext.json
```

Expected: a small JSON object with two fields. `auth_token` holds a value that starts with `eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9` and ends with three dots, and `pan` holds a 16-digit card number that starts with `4532`.

![Steps 1, 3 and 4 in one terminal: the missing folder, the new file, and the JSON record](images/lab-02/terminal-steps-1-4.png)

!!! tip "Notice what this read did not need"
    No root. No `run-as`. No debug hook. Your plain adb shell user read the file as it is. That is the whole finding, and the rest of the lab just proves it from more angles.

    The result card may claim this only works below API 29. That sentence describes ordinary apps on a phone; an adb shell can still read the folder.

### 5. Take it off the device

```bash
adb pull /sdcard/Android/data/com.hasantuncay.mobsec/files/maswe0002_plaintext.json .
cat maswe0002_plaintext.json
```

Expected: `1 file pulled, 0 skipped.` followed by the same JSON, now sitting on your machine. Newer `adb` versions print the source path and a transfer rate around that line. One command, one copy, on a computer.

### 6. Ask the app to encrypt something

Go back to the module screen and tap the third button: `3. External Storage + Key on Filesystem`. Then:

```bash
adb shell ls -la /sdcard/Android/data/com.hasantuncay.mobsec/files/
```

Expected: two new files, `maswe0002_key_on_fs.enc` and `maswe0002_secret.key`.

### 7. Read the key

```bash
adb shell od -An -tx1 /sdcard/Android/data/com.hasantuncay.mobsec/files/maswe0002_secret.key
```

Expected: two lines of hex bytes, 32 in total. That is the AES key for the `.enc` file sitting next to it, written to the same shared folder. Run the same command on `maswe0002_key_on_fs.enc` if you want to see the ciphertext it protects.

![Steps 6 and 7 in one terminal: the new files and the 32-byte key in hex](images/lab-02/terminal-steps-6-7.png)

### 8. Optional: let the project's checker confirm it

If you have the project repository on this machine, the module ships a script that repeats the key parts of this inspection:

```bash
bash features/maswe0002/poc/adb_verify.sh
```

Expected: `[!] CRITICAL VULNERABILITY CONFIRMED (MASWE-0002 / CWE-732):` followed by the plaintext record it could read from `/sdcard/Android/data/...` and the key file it found beside the ciphertext.

---

## C · Look & tell

Answer these in your notes before moving on:

1. ✍️ Lab 01 needed `run-as` for its read. This lab needed nothing beyond adb. What is the difference between the two locations, and who can reach each one on a real device?
2. ✍️ Vector 3 did encrypt the data before writing it out. Why does that not rescue the storage choice? Where did the key end up?
3. ✍️ You copied the record off the device in one command. Name one concrete thing an attacker can do with it.

---

## D · Prove it

You have the finding when all four are true:

| Test | What it shows |
|---|---|
| The step 1 and step 3 listings | A file appeared outside the app's private sandbox, minutes after the app wrote it |
| The step 4 output | A token and a card number readable with a plain adb shell user, no root and no `run-as` |
| The step 5 output | A copy of the record now exists on your machine, pulled with one command |
| The steps 6 and 7 outputs | The encrypted file keeps its AES key in the same shared folder, as a file anyone can read |

If you ran step 8, its output is a second, independent confirmation of the same artifacts. Attach it as well.

---

## E · Your evidence

Hand in:

1. 📷 Screenshot 1: your terminal with the step 3 listing and the step 4 output. The token and the card number must be readable, not cut off.
2. 📷 Screenshot 2: the step 6 listing and the step 7 hex key, or the step 5 pull and host-side `cat`.
3. ✍️ Two or three sentences, in your own words:
   - what was written and to which kind of storage,
   - why the encrypted file does not fix the problem,
   - one concrete thing an attacker could do with the record.

Submit these through your training channel. No long report is needed.

---

## F · Stuck?

??? question "Hint 1: Permission denied on the folder"
    - Some emulator images restrict `/sdcard/Android/data` from the shell user. Lab 00 picks an image without the Play Store so `adb root` works. Run `adb root`, wait for the restart, then repeat the command.
    - This only applies to the read steps. If step 1 printed `No such file or directory`, that is not a permission problem; the folder simply does not exist yet.

??? question "Hint 2: the folder is still missing after the tap"
    - Confirm the tap landed: the button turns red and the app shows a result card you were told to ignore.
    - Wait a second and list again. The directory is created with the first write.
    - Check the package name in the path: `com.hasantuncay.mobsec`, no `.vulnerable` suffix.

??? question "Hint 3: od or cat misbehaves"
    - `od` is a standard part of the device shell. If it fails anyway, pull the file and inspect it on your machine: `adb pull .../maswe0002_secret.key .` then `od -An -tx1 maswe0002_secret.key`.
    - The JSON file is plain text, so `cat` is enough for it. If the output looks garbled, you are reading the wrong file.

---

## G · Reveal

!!! warning "Open only after sections C and E are done"
    Your screenshots are the evidence, not this section. Read it last.

??? question "What you actually found"
    This is **CWE-732: Incorrect Permission Assignment for Critical Resource**, applied to storage: MASWE-0002.

    Every vector in this module writes through `getExternalFilesDir()`, which lands in `/sdcard/Android/data/com.hasantuncay.mobsec/files/`. That path looks private because it names the app, but it sits on shared storage, outside the app's sandbox. The plaintext JSON held an auth token and a card number, and your plain adb shell read it without any privilege escalation. On older Android versions any app holding storage permission could read the same folder; on any device, root, a forensic pull, or USB debugging reads it.

    Vector 3 then shows the second layer: it encrypted the payload properly with AES, and wrote the 32-byte key to `maswe0002_secret.key` in the same folder. Encryption that ships its key alongside the ciphertext protects nothing. The other buttons continue the pattern: a hardcoded key, DES with the literal key `WeakKey1`, and a key derived from `ANDROID_ID`, which is stable per device and not a secret.

    Why it matters:

    - Card numbers and tokens are regulated data. PCI-DSS treats readable storage as a finding on its own.
    - A record in shared storage leaves the device easily: a file manager, a USB connection, a backup tool, or one `adb pull`.
    - Once copied, deleting the app or the file does not retract any copy.
    - "The data was encrypted" is worth nothing when the key takes the same trip as the data.

    What the secure app does instead:

    The `:app-secure` implementation writes through Jetpack Security's `EncryptedFile` (AES-256-GCM with an HKDF-derived key), with the master key held in the Android Keystore, and keeps the one plaintext copy inside the private sandbox. The key never leaves hardware-backed storage.

    Go deeper:

    - Reference page: [MASWE-0002: Sensitive Data Stored Unencrypted Outside of Private Storage](../maswe/MASVS-STORAGE/maswe_002/MASWE-0002-Insecure-Storage.md)
    - The vulnerable code lives in `features/maswe0002/src/main/java/com/hasantuncay/mobsec/maswe0002/vulnerable/Maswe0002VulnerableRepository.kt`.
    - The module's automation is in `features/maswe0002/poc/`: a Semgrep rule pack for CI, a Frida hook for runtime inspection, and the `adb` script from step 8.
