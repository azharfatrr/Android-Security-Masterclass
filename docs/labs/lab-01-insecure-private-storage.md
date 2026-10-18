# Lab 01: The Token That Stayed in Plain Sight

| | |
|---|---|
| **Module** | [MASWE-0001: Sensitive Data Stored Unencrypted in Private Storage](../maswe/MASVS-STORAGE/maswe_001/MASWE-0001-Insecure-Private-Storage.md) |
| **Category** | MASVS-STORAGE |
| **CWE** | CWE-312: Cleartext Storage of Sensitive Information |
| **Time** | ~25 minutes |
| **Level** | Beginner |
| **Needs** | [Lab rules](index.md#before-you-conduct-any-lab) read · [Lab 00: Setup](setup.md) complete · **🎯 MobSec Victim** installed · `adb` working |

!!! info "Self-paced lab"
    You work through this alone and at your own pace. The app does one thing for you here: it stores the data when you tell it to. Everything after that tap is yours to investigate with your own commands. Section E tells you exactly what to capture as proof.

---

## A · Requirement

The app stores a signed access token that authenticates the user. It should keep the token where nothing outside the app can read it, and its encryption keys should be just as private.

Make the app store the token, then find it on disk with your own commands and read the value out. Then find the app's own attempt at encryption and check where its key ended up.

The app has a screen full of demo buttons. They write the data. They do not answer the question of what landed on disk, and one of them may even print a path on screen.

Do not read the project source code. Use the installed app and your terminal.

---

## B · Validation

Run everything in one terminal (Git Bash on Windows). This lab needs the emulator running and the app installed.

### 1. Take a "before" reading

List the app's own file storage before you touch the app:

```bash
adb shell run-as com.hasantuncay.mobsec ls -la files
adb shell run-as com.hasantuncay.mobsec ls -la files/datastore
```

`run-as` opens the app's private folder as the app itself. It works because Lab 00 installs a debug build. On a normal phone, the same read needs root.

Expected: the first command lists a short set of entries, or prints `No such file or directory`. The second usually prints `No such file or directory`. Either way, note what you see. You are taking a snapshot.

!!! tip "The app writes a result card after every button"
    Ignore it. It repeats what the demo was built to say. Your evidence comes from your terminal, not from the app's summary of itself.

### 2. Make the app store the value

Open **🎯 MobSec Victim**. The dashboard groups modules by category. Tap `MASVS-STORAGE` to expand it:

![The dashboard with MASVS-STORAGE expanded](images/lab-01/dashboard-storage-expanded.png){ width="360" }

Then open the `MASWE-0001` row.

!!! note "One label lies"
    The row subtitle reads `MASWE-0001: Private Storage (SECURE)`. That wording is a bug in this training build. The screen title bar is what counts, and it says `MASWE-0001 (VULNERABLE)`.

The module screen lists six vectors. This lab uses the first and the third:

![The MASWE-0001 screen with its six vector buttons](images/lab-01/maswe0001-buttons.png){ width="380" }

Tap the first button: `1. Data Stored Unencrypted (Cleartext)`.

### 3. Look again

```bash
adb shell run-as com.hasantuncay.mobsec ls -la files
adb shell run-as com.hasantuncay.mobsec ls -la files/datastore
```

Expected: `files` now contains a `datastore` directory, and inside it is one file, `maswe0001_v1.preferences_pb`. Some DataStore versions also leave a small lock file next to it; this one does not. Owner, size, and date are whatever your emulator reports; the name is the part that matters.

```text
-rw------- 1 u0_a2XX u0_a2XX  1234 2026-..-.. ..:.. maswe0001_v1.preferences_pb
```

That file did not exist a minute ago. The button you tapped is the only thing that changed.

### 4. Read the stored value

The file is not plain text; it is a protobuf blob with the token embedded. `grep` with `-a` reads it as text and keeps the readable run:

```bash
adb exec-out run-as com.hasantuncay.mobsec cat files/datastore/maswe0001_v1.preferences_pb | grep -a eyJ
```

Expected: a single line containing `auth_token` and a value that begins with `eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9`. A few unprintable bytes from the protobuf wrapper may sit around it. Copy the `eyJ...` run into your notes exactly; in this training data it ends with three dots.

![Steps 3 and 4 in one terminal: the new file and the token line](images/lab-01/terminal-steps-3-4.png)

No `grep` output means one of two things: you listed the wrong folder, or the button tap did not land. Tap the vector again, count to two, and rerun the command.

### 5. Make the app try to encrypt something

Go back to the app screen and tap the third button: `3. Encryption Key Stored on Filesystem`.

### 6. Find the pair

```bash
adb shell run-as com.hasantuncay.mobsec ls -la files
adb shell run-as com.hasantuncay.mobsec ls -la shared_prefs
```

Expected: `files` gained `maswe0001_v3.enc`, and `shared_prefs` gained `maswe0001_v3_keys.xml`. Those two names are a pair. One holds encrypted data; the other holds the thing that unlocks it. `shared_prefs` may also hold unrelated XML files from earlier app starts; only the new `maswe0001_v3_keys.xml` matters here.

### 7. Read the key

```bash
adb shell "run-as com.hasantuncay.mobsec cat shared_prefs/maswe0001_v3_keys.xml"
```

Expected: a small XML file with one entry, `<string name="aes_key">` followed by a long base64 value. That value is the AES key the app used for `maswe0001_v3.enc`. It sits in the same storage, one folder over, in the clear.

![Steps 6 and 7 in one terminal: the encrypted file, the key file, and the key in the clear](images/lab-01/terminal-steps-6-7.png)

### 8. Optional: let the project's checker confirm it

If you have the project repository on this machine, the module ships a script that looks for the same two artifacts:

```bash
bash features/maswe0001/poc/adb_verify.sh
```

Expected: `[!] CRITICAL VULNERABILITY CONFIRMED (MASWE-0001 / CWE-312):` followed by the files it could read, including the one from step 4. The script also checks the other storage vectors' files, so the report can list more than the two you created. Anything extra is a bonus find, not part of the exercise.

---

## C · Questions

Answer these in your notes before moving on:

1. ✍️ The `datastore` folder lives inside the app's private storage. Who can normally read that folder on a real phone, and what made it readable for you without root?
2. ✍️ Vector 3 did encrypt the data. Explain in your own words why the finding stands anyway: where did the key end up, and what does that mean for someone holding a copy of the device storage?
3. ✍️ What can an attacker do with the value you pulled out in step 4? Name one concrete action.

---

## D · Finding

You have the finding when all four are true:

| Test | What it shows |
|---|---|
| The step 3 listing | A new file appeared in the app's private storage right after the app processed data |
| The step 4 output | The app stored a usable token in cleartext, readable byte for byte, with no decryption step anywhere |
| The steps 6 and 7 outputs | The app's encrypted file keeps its AES key in a separate file in the same private storage |
| Section C, question 3 | One sentence of impact: what an attacker does with what they read |

If you ran step 8, its output is a second, independent confirmation of the same files. Attach it as well.

---

## E · Evidence

Hand in:

1. 📷 Screenshot 1: your terminal with the step 3 listing and the step 4 output. The token value must be readable, not cut off.
2. 📷 Screenshot 2: the step 6 listing and the step 7 key file.
3. ✍️ Two or three sentences, in your own words:
   - what was stored without encryption and where,
   - why the encrypted file from vector 3 does not save the situation,
   - one concrete thing an attacker could do with the token.

Submit these through your training channel. No long report is needed.

---

## F · Hints

??? question "Hint 1: the app or the buttons are not where I expect"
    - The dashboard groups modules under category cards. Expand `MASVS-STORAGE` first.
    - The row subtitle may mention SECURE; ignore it and check the screen title bar for `MASWE-0001 (VULNERABLE)`.
    - Only buttons 1 and 3 matter for this lab. If a tap produces no visible change, tap it again and give the app a second to write.

??? question "Hint 2: storage looks empty or different from the page"
    - List first, tap second, list again third: step 1 records the snapshot, step 3 shows the change.
    - `run-as: package not debuggable` means the release build is installed. Reinstall the debug APK from Lab 00.
    - `ls` may print `No such file or directory` for `files/datastore` until vector 1 has run once.

??? question "Hint 3: the cat output is noisy or empty"
    - The DataStore file is binary with the token inside. Run the step 4 pipe exactly as written: `adb exec-out ... | grep -a eyJ`.
    - If the pipe prints a warning about binary data, you dropped the `-a`. It is the flag that keeps the matches readable.
    - The XML key file is plain text, so step 7 needs no pipe. If it prints nothing, the vector 3 tap did not land.

---

## G · Explanation

!!! warning "Open only after sections C and E are done"
    Your screenshots are the evidence, not this section. Read it last.

??? question "What you actually found"
    This is **CWE-312: Cleartext Storage of Sensitive Information**, the core of MASWE-0001.

    Vector 1 wrote an OAuth-style bearer token into a Jetpack DataStore file (`files/datastore/maswe0001_v1.preferences_pb`) with no encryption applied. DataStore is a tidy container, not a safe; anyone who can read the file reads the token.

    Vector 3 is the one that catches people out. The app did encrypt the record with AES, then stored the AES key in `shared_prefs/maswe0001_v3_keys.xml`. Encryption where the key sits next to the data stops only the attackers who can read neither file. Anyone with the storage, which includes root malware, a forensic image, or a rooted inspection like yours, gets both halves.

    The module demonstrates four more storage habits on its other buttons: a key hardcoded in the app package, AES in ECB mode, a FileProvider whose path config maps far more of the filesystem than it should, and a cache file that is never deleted.

    Why it matters:

    - Tokens recovered from storage authenticate as the user until they expire or are revoked.
    - "It is in private storage" is not a defense once the device is rooted, imaged, or the build is debuggable. The data needs encryption with a key the attacker cannot reach.
    - An encryption key stored on the same filesystem as its ciphertext travels with the ciphertext wherever it goes.

    What the secure app does instead:

    The `:app-secure` implementation keeps its encryption keys in the Android Keystore and wraps storage with Tink AEAD (`AndroidKeystore` master key, encrypted DataStore serializer). Vector 3's secure counterpart uses envelope encryption, with the key-encrypting key in hardware and only a wrapped data key on disk.

    Go deeper:

    - Reference page: [MASWE-0001: Sensitive Data Stored Unencrypted in Private Storage](../maswe/MASVS-STORAGE/maswe_001/MASWE-0001-Insecure-Private-Storage.md)
    - The vulnerable code lives in `features/maswe0001/src/main/java/com/hasantuncay/mobsec/maswe0001/vulnerable/Maswe0001VulnerableRepository.kt`.
    - The module's automation is in `features/maswe0001/poc/`: a Semgrep rule for CI scanning, a Frida hook for runtime inspection, and the `adb` script from step 8.
