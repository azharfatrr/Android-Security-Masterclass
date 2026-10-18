# Writing a lab (internal template)

This page is for whoever writes and proofs the labs. Students do not need it.

Every lab follows the same seven sections. Change the shape only when a module genuinely cannot fit it, and record the reason in the verification file.

---

## The shape

### A · Requirement

One short paragraph giving the requirement: the protection the app is supposed to provide, in plain terms, with no sign of whether it holds. A second short paragraph says what to run against the installed app. Leave out the location, tool names that give the approach away, and any explanation of the vulnerability.

### B · Validation

Numbered, literal, and runnable exactly as written.

- Use the exact UI labels from `app-vulnerable`, including case, punctuation, and numbering.
- Put exact commands in fenced `bash` blocks. One command per block when order matters.
- Every command that can fail gets an **Expected** line showing the shape of the output.
- When a command needs something from an earlier step, say so ("the path from step 6").
- If a step needs root, Wi-Fi, or a second terminal, say it in that step.
- The shell is **Git Bash** on Windows. Add a macOS/Linux note only where commands differ.
- The employee must not read the source code. Even when the source is the easiest way to see the issue, route the finding through the running app or the installed package.
- The finding is the employee's own work. Route it through their own commands against the installed package or the running app. The app's built-in vector buttons and the module's `poc/` scripts may appear only after the manual finding, as confirmation or automation. A script step is marked optional when it needs the project repository.
- When the vulnerability lives in the app file itself (hardcoded secrets, embedded files), prefer package analysis. The learner pulls the file apart and the app's screens stay closed.

### C · Questions

Three questions maximum, all requiring the employee to write something. No yes/no questions. The questions should make them state what they observed, where exactly it was, and why it matters.

### D · Finding

An objective checkpoint: the same fact confirmed through two independent channels (runtime against static, app against file, vulnerable against secure). When the finding lives entirely in the app package (hardcoded secrets, embedded files), the two channels are the employee's manual extraction and an independent check of the same artifact, for example the module's script. Give the employee a table or checklist that says when the finding is complete. Leave interpretation out of it.

### E · Evidence

Exactly what gets handed in: screenshot prompts that name the artifact, plus a description template of two or three sentences. Keep it short. The evidence is the deliverable, not a report.

### F · Hints

At most three ordered hints. Hints fix the environment or the procedure and never reveal the value or the conclusion. Prefer commands the employee can run to diagnose (`adb devices`, `ls`, re-run the step) over explanations.

### G · Explanation

Behind a collapsible block, guarded by "open only after your evidence":

- the CWE and MASWE mapping,
- why the finding matters, with concrete impact,
- what the `:app-secure` counterpart does,
- links to the reference page, POC scripts, and the relevant MASTG test. Name the script paths and the exact command to run them.

---

## File and nav conventions

| What | Where |
|---|---|
| Lab file | `docs/labs/lab-NN-<slug>.md`, where `NN` is the MASWE number |
| Setup lab | `docs/labs/setup.md` (Lab 00, shared by all labs) |
| Index row | `docs/labs/index.md`, table at the bottom |
| Nav entry | `mkdocs.yml`, under `🧪 Hands-on Labs` |
| Proof checklist | `docs/labs/verification/lab-NN.md`, not added to the nav |

Each lab starts with the metadata table (module, category, CWE, time, level, needs) and links back to the reference page under `docs/maswe/`.

Status values in the index:

- 🧪 **Awaiting proof run**: written, not yet run end to end on a clean emulator.
- ✅ **Ready**: every step confirmed in one clean run.
- ⚠️ **Known issue**: a step is known to fail in some environments; the note says which.

---

## POC scripts in labs

Each feature module may ship scripts under `features/<module>/poc/`. In a lab they are allowed only as a confirmation stage after the manual finding, never as the way the finding is made.

Before a script appears in a lab, test it against the real app:

- The package id must be `com.hasantuncay.mobsec`. The original `adb_verify.sh` targeted `com.hasantuncay.mobsec.vulnerable`, a package that exists on no device.
- The patterns must match the module's planted values. The same script missed every `mock_secret_` style value until it was fixed.
- It must run on Git Bash. Check `unzip`, `mktemp`, and `grep -a` before the step ships.

If a script cannot find the module's motif, fix the script or leave it out. A confirmation step that reports nothing is worse than no step.

---

## Proof protocol (run before a lab is marked ✅)

1. **Start clean.** Cold-boot the emulator, run `adb uninstall com.hasantuncay.mobsec`, then reinstall the APK. Do not reuse a session from earlier work.
2. **Run Lab 00 first**, exactly as written. If setup fails, the lab cannot be proven.
3. **Run the lab literally.** Follow the steps in order without using your knowledge of the code. Type the commands from the page, not from memory.
4. **Record each step.** In the verification file, mark pass or fail and note any difference in labels, paths, output text, or timing.
5. **Run every optional step once too**, in the same session, including the module's POC script pointed at both the pulled APK and the installed app. A script that reports nothing is broken; fix it or the step before shipping.
6. **Fix the lab, not the note.** If a step behaves differently, rewrite the step. A difference that cannot be avoided goes into a `!!! note` block on the lab page.
7. **Record the environment:** emulator product and image (Android Studio AVD or Genymotion), API level, host OS, terminal (Git Bash, zsh, PowerShell), and whether the app came from a provided APK or a local build.
8. Only after a full clean pass: change the index status to ✅ and date the verification file.

If a lab cannot be finished because the app itself is incomplete (missing screen, dead button), record it as a ⚠️ known issue and open a repo issue. The lab does not ship as ✅.
