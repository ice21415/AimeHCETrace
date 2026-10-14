# AimeHCETrace

Metadata-only diagnostic tweak for nfcd HCE calls. This is not an Aime emulator.
Each hook checks its method ABI and forwards to the original implementation.
Logs contain method names and success/presence outcomes, never card payloads.
No NFC sessions or routing changes are initiated by the tweak.

CI builds arm64 and arm64e with macOS/Xcode and pinned RootHide Theos.
Artifacts include Debian packages, dylibs, build logs and SHA-256 checksums.
Compilation does not prove device loader compatibility or successful hooking.

The opt-in file `/var/tmp/aime-hce-trace.enabled` must exist before loading.
Removing it stops logging but does not unhook an already running process.
Full removal requires uninstalling and restarting the affected service/device.
No automatic activation or service restart scripts are packaged.
Only synchronous readAPDU is observed; async activity may bypass these hooks.

No credentials, SSH scripts, card data, SDKs or firmware are included.
