/**
 * OWASP MASWE-0001: Sensitive Data Stored Unencrypted in Private Storage
 * Frida Runtime SharedPreferences & Local Storage Hook
 *
 * Usage:
 *   frida -U -f com.hasantuncay.mobsec -l frida_hook.js
 */

Java.perform(function () {
    console.log("[*] MASWE-0001 SharedPreferences & Private Storage Inspector Initialized...");

    // 1. Hook SharedPreferencesImpl.getString to detect cleartext token reads
    try {
        var SharedPreferencesImpl = Java.use("android.app.SharedPreferencesImpl");
        SharedPreferencesImpl.getString.overload("java.lang.String", "java.lang.String").implementation = function (key, defValue) {
            var value = this.getString(key, defValue);
            var lower = key.toLowerCase();
            if (lower.indexOf("auth") !== -1 || lower.indexOf("pass") !== -1 || lower.indexOf("token") !== -1 || lower.indexOf("secret") !== -1) {
                console.log("\x1b[31m[!] CLEARTEXT PRIVATE STORAGE READ DETECTED:\x1b[0m");
                console.log("    Key  : " + key);
                console.log("    Value: " + value);
            }
            return value;
        };
    } catch (e) {
        console.log("[-] SharedPreferencesImpl hook error: " + e);
    }

    // 2. Hook SharedPreferences Editor putString to capture sensitive writes
    try {
        var EditorImpl = Java.use("android.app.SharedPreferencesImpl$EditorImpl");
        EditorImpl.putString.overload("java.lang.String", "java.lang.String").implementation = function (key, value) {
            console.log("\x1b[33m[*] SharedPreferences Write -> Key: " + key + " | Value: " + value + "\x1b[0m");
            return this.putString(key, value);
        };
    } catch (e) {
        console.log("[-] EditorImpl hook error: " + e);
    }
});
