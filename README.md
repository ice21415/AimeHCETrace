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

Version 0.1.1 writes `/var/tmp/aime-hce-trace.log`: `loaded`, `disabled`,
`hook_missing`, `hook_abi_mismatch`, `hook_installed`, and `call` events include
timestamps and process IDs. The file is append-only, mode 0600 on creation,
rejects symlinks, and stops writing at 256 KiB. Failure to open it falls back
to NSLog. A missing log does not distinguish missing injection from denied
file access. `hook_installed` confirms a saved original IMP, not an RF transaction.

No credentials, SSH scripts, card data, SDKs or firmware are included.

## RootHide system-daemon paths

On the tested device, SSH runs inside the jailbreak filesystem while nfcd uses
the system filesystem. In that SSH namespace, use
`/rootfs/private/var/tmp/aime-hce-trace.enabled` for the opt-in flag and
`/rootfs/private/var/tmp/aime-hce-trace.log` to read the log. A flag under the
jailbreak's own `/var/tmp` was invisible to nfcd. Confirm the namespace on other
devices before changing files. The tested nfcd runs as mobile (UID 501).

Version 0.1.1 has been observed to log `loaded` and all three `hook_installed`
events on iOS 17.1.2 after restart. This verifies initialization and saved
original IMPs; no HCE invocation or RF card emulation has been demonstrated.
