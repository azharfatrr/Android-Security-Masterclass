/**
 * OWASP MASWE-0004: Sensitive Data Hardcoded in App Package
 * Frida Runtime Secret Extraction & Memory Inspection Hook
 *
 * Usage:
 *   frida -U -f com.hasantuncay.mobsec -l frida_hook.js
 */

Java.perform(function () {
    console.log("[*] MASWE-0004 Memory & Secret Inspector Initialized...");

    // 1. Hook OkHttp Request Builder to detect hardcoded Authorization / API keys
    try {
        var RequestBuilder = Java.use("okhttp3.Request$Builder");
        RequestBuilder.addHeader.overload("java.lang.String", "java.lang.String").implementation = function (headerName, headerValue) {
            var lower = headerName.toLowerCase();
            if (lower.indexOf("auth") !== -1 || lower.indexOf("key") !== -1 || lower.indexOf("secret") !== -1 || lower.indexOf("token") !== -1) {
                console.log("\x1b[31m[!] HARDCODED SECRET LEAK DETECTED IN NETWORK HEADER:\x1b[0m");
                console.log("    Header Name : " + headerName);
                console.log("    Header Value: " + headerValue);
            }
            return this.addHeader(headerName, headerValue);
        };
    } catch (e) {
        console.log("[-] OkHttp hook skipped: " + e);
    }

    // 2. Trace string comparisons against known secret formats (sk_live_, AIza, AKIA)
    try {
        var StringClass = Java.use("java.lang.String");
        StringClass.startsWith.overload("java.lang.String").implementation = function (prefix) {
            if (prefix === "sk_live_" || prefix === "AIza" || prefix === "AKIA") {
                console.log("\x1b[33m[*] Secret prefix check observed in runtime: " + prefix + "\x1b[0m");
            }
            return this.startsWith(prefix);
        };
    } catch (e) {
        console.log("[-] String hook skipped: " + e);
    }
});
