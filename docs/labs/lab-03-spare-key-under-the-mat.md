# Lab 03: The Spare Key Under the Mat

| | |
|---|---|
| **Module** | [MASWE-0003: Cryptographic Keys Stored Outside of Platform Keystore](../maswe/MASVS-STORAGE/maswe_003/MASWE-0003-Insecure-Key-Storage.md) |
| **Category** | MASVS-STORAGE · MASVS-CRYPTO |
| **CWE** | CWE-312: Cleartext Storage of Sensitive Information |
| **Time** | ~25 minutes |
| **Level** | Beginner |
| **Needs** | [Lab rules](index.md#before-you-conduct-any-lab) read · [Lab 00: Setup](setup.md) complete · **🎯 MobSec Victim** installed · `adb` working |

!!! info "Self-paced lab"
    The app creates the key material when you tap its buttons; finding where the copies went is your work. You will read one copy out of a file and decode it, then catch the second copy in the system log. Section E tells you exactly what to capture as proof.

---

## A · Mission

Android ships a place built for one job: keeping cryptographic keys away from everyone, including the app that uses them. It is called the Keystore, and keys that live there never exist as readable bytes at all.

This app skipped it twice. It generated an AES key and wrote a full copy into a preferences file, and it pasted more key material into the system log where a debugging session picks it up.

Find both copies with your own commands, and prove that each one is real key material rather than a reference. Then explain why a copy like that defeats the point of encryption.

Do not read the project source code. Use the installed app and your terminal.

---

## B · Steps

Run everything in one terminal (Git Bash on Windows). The app's result cards explain themselves after each tap; ignore them and build your evidence from your own commands.

### 1. Look before

```bash
adb shell run-as com.hasantuncay.mobsec ls -la shared_prefs
```

Expected: a short listing, or `No such file or directory` if this is your first storage lab. Note what you see; you are taking a snapshot.

### 2. Make the app store its key

Open **🎯 MobSec Victim**, expand `MASVS-STORAGE`, and open the `MASWE-0003` row.

!!! note "One label lies"
    The row subtitle may read something with SECURE in it. That is a bug in this training build. The screen title bar is what counts: `MASWE-0003 (VULNERABLE)`.

The module lists three vectors. This lab needs the first and the third:

![The MASWE-0003 screen with its three vector buttons](images/lab-03/maswe0003-buttons.png){ width="380" }

!!! warning "The result cards hand you the answer"
    After each tap the card prints the path or the log command you are meant to find. Treat it as a spoiler: run your own commands first, and read the card only if you are stuck.

Tap the first button: `1. Key in SharedPreferences / File`.

### 3. Look again

```bash
adb shell run-as com.hasantuncay.mobsec ls -la shared_prefs
```

Expected: a new file, `crypto_key.xml`. That is the app's SharedPreferences store, and its name already says what is inside.

### 4. Read the stored key

```bash
adb shell "run-as com.hasantuncay.mobsec cat shared_prefs/crypto_key.xml"
```

Expected: a small XML file with one entry, `<string name="aes_key">` followed by a base64 value. The value sits on one line, and a trailing encoded newline (`&#10;`) and spaces can follow inside the element; the next command handles that. The app generated an AES key and wrote the encoded bytes straight to disk. The write is asynchronous, so if the entry is missing, wait a second and read again.

### 5. Prove it is a real key, not a note

A reference or an alias would not survive decoding. This value does:

```bash
adb exec-out run-as com.hasantuncay.mobsec cat shared_prefs/crypto_key.xml | grep -o -E '[A-Za-z0-9+/]{40,}={0,2}' | head -n 1 | base64 -d | wc -c
```

The `grep` pulls the base64 run out of the XML, the decoder turns it back into bytes, and `wc -c` counts them.

Expected: `32`. That is the raw length of an AES-256 key in bytes. The file does not describe a key; it holds the key, in a form anyone who reads the file can decode and use.

![Steps 3, 4 and 5 in one terminal: the key file, the XML, and the decoded byte count](images/lab-03/terminal-steps-3-5.png)

### 6. Catch the second copy in the log

Clear the log buffer so nothing else drowns your line:

```bash
adb logcat -c
```

Now go back to the module screen and tap the third button: `3. Plaintext Key Import`.

Then dump the log:

```bash
adb logcat -d -s MASWE_0003_KEY_IMPORT
```

Expected: a line reading `Importing key: ` followed by a plain, readable string. That is key material written into the system log for anyone with log access to find. If the dump is empty, tap the button again and rerun the command immediately.

![Step 6 in the terminal: the log line with the imported key](images/lab-03/terminal-step-6.png)

### 7. Optional: let the project's checker confirm it

If you have the project repository on this machine, the module ships a script that repeats both reads:

```bash
bash features/maswe0003/poc/adb_verify.sh
```

Expected: `[!] CRITICAL VULNERABILITY CONFIRMED (MASWE-0003 / CWE-312):` followed by the key file it could read (with its decoded byte length) and the log line it found.

---

## C · Look & tell

Answer these in your notes before moving on:

1. ✍️ The AES key existed as 32 readable bytes in a file. Where do app keys normally live on Android, and what is different about them there?
2. ✍️ The log line is one `adb` command away while a device is attached for debugging. Name one more way log lines leave a device in normal operation.
3. ✍️ With the key from step 4 in hand, what can an attacker do that they could not do without it? Name one concrete action.

---

## D · Prove it

You have the finding when all four are true:

| Test | What it shows |
|---|---|
| The step 3 listing | A preferences file appeared minutes after the app generated a key |
| The step 4 output | The file holds a full base64 copy of the AES key, in the clear |
| The step 5 output | The copy decodes to 32 bytes of raw key material, ready to use |
| The step 6 output | More key material landed in the system log, readable with one command |

If you ran step 7, its output is a second, independent confirmation of the same artifacts. Attach it as well.

---

## E · Your evidence

Hand in:

1. 📷 Screenshot 1: your terminal with the step 4 XML output and the step 5 `32` result on screen.
2. 📷 Screenshot 2: the step 6 log line.
3. ✍️ Two or three sentences, in your own words:
   - where the two copies of key material ended up,
   - what the Keystore would have done differently,
   - one concrete thing an attacker could do with a copied key.

Submit these through your training channel. No long report is needed.

---

## F · Stuck?

??? question "Hint 1: run-as or the file read fails"
    - `run-as: package not debuggable` means the release build is installed. Reinstall the debug APK from Lab 00.
    - `No such file or directory` for `shared_prefs` means the button has not run yet. Tap `1. Key in SharedPreferences / File` and list again.

??? question "Hint 2: the XML is there but the entry looks odd"
    - The write is asynchronous. Wait one second, then `cat` again.
    - The value is base64, so it can contain `+`, `/`, and `=`. Copy it whole if you want to decode it by hand.
    - If you are on macOS instead of Git Bash, `base64 -d` may need to be `base64 -D`.

??? question "Hint 3: the logcat dump is empty"
    - Clear the buffer first (`adb logcat -c`), tap the third button, then dump immediately. Busy emulators rotate the buffer quickly.
    - The tag is exact: `MASWE_0003_KEY_IMPORT`, with underscores.
    - Still empty, try without the filter: `adb logcat -d | grep MASWE_0003`.

---

## G · Reveal

!!! warning "Open only after sections C and E are done"
    Your screenshots are the evidence, not this section. Read it last.

??? question "What you actually found"
    This is **MASWE-0003**, covering **CWE-312** (cleartext storage) and **CWE-321** (hardcoded cryptographic key).

    Vector 1 generated a fresh AES-256 key, encoded it with `Base64.DEFAULT`, and stored it in `shared_prefs/crypto_key.xml` under the name `aes_key`. The key exists as readable bytes, so the app is not protecting it; it is only keeping it tidy. Vector 3 wrote more key material to the system log with one `Log.d` call, where debug sessions, bug reports, and logging pipelines copy it around.

    Vector 2 completes the set: a key hardcoded as a byte array in the app's bytecode. It never touches the disk, it ships with the app, and tools like jadx or apktool recover it in seconds.

    Why it matters:

    - A key you can copy is a key an attacker can copy. Filesystems get imaged, logs get collected, packages get unpacked.
    - Keys outside the Keystore cannot be protected by hardware: no attestation, no non-exportability, no user authentication binding.
    - Rotation becomes guesswork, because you can never prove where copies ended up.

    What the secure app does instead:

    The `:app-secure` implementation generates its keys inside the Android Keystore (`KeyGenerator.getInstance(KEY_ALGORITHM_AES, "AndroidKeyStore")`), with StrongBox preferred where the hardware offers it, and nothing is written to preferences or logs. For keys that must arrive from a server, it points at Keystore wrapped key import instead of shipping raw material.

    Go deeper:

    - Reference page: [MASWE-0003: Cryptographic Keys Stored Outside of Platform Keystore](../maswe/MASVS-STORAGE/maswe_003/MASWE-0003-Insecure-Key-Storage.md)
    - The vulnerable code lives in `features/maswe0003/src/main/java/com/hasantuncay/mobsec/maswe0003/vulnerable/Maswe0003VulnerableRepository.kt`.
    - The module's automation is in `features/maswe0003/poc/`: a Semgrep rule pack for CI, a Frida hook for runtime inspection, and the `adb` script from step 7.
