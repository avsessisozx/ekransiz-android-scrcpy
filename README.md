# Screenless Android â†’ PC over adb + scrcpy

How to regain control of an Android phone whose display is physically gone â€” from a PC, over USB, with **adb** and **scrcpy** â€” on a device whose ROM keeps disabling USB debugging at boot.

**Tested on:** Xiaomi Redmi Note 10 Pro (`sweet` / `M2101K6G`), OrangeFox R12.1_3, Android 13 (`TQ3A.230901.001.B1`, userdebug), verity disabled (`vbmeta flags=0x3`).

ğŸ“„ **Full write-up:** [English](https://avsessisozx.github.io/ekransiz-android-scrcpy/) Â· [TÃ¼rkÃ§e](https://avsessisozx.github.io/ekransiz-android-scrcpy/tr/)

---

## The short version

1. Boot **OrangeFox recovery** (Power + Volume Up). Recovery adbd runs with `ro.adb.secure=0`, so you get a root shell.
2. Check that verity is off before touching `/system` (`avbctl get-verity`).
3. Pre-seed the PC key into `/data/misc/adb/adb_keys` (`system:shell`, `0640`, label `adb_keys_file`).
4. Editing `adb_enabled` in `settings_global.xml` **does not survive boot** â€” SettingsProvider rewrites the file and the value reverts to `0`.
5. The fix: an **init script** in `/system/etc/init` that runs at `sys.boot_completed`:

```sh
# /system/etc/adb_boot.sh
#!/system/bin/sh
i=0
while [ $i -lt 20 ]; do
  settings put global adb_enabled 1 && break
  sleep 2
  i=$((i+1))
done
setprop sys.usb.config mtp,adb
```

```
# /system/etc/init/adb_boot.rc
service adb_boot /system/bin/sh /system/etc/adb_boot.sh
    class late_start
    user root
    group root
    seclabel u:r:su:s0
    oneshot
    disabled

on property:sys.boot_completed=1
    setprop sys.usb.config mtp,adb
    start adb_boot
```

6. `chmod` / `chown` / `chcon u:object_r:system_file:s0`, `sync`, reboot. ~20 s later adb is back.
7. Mirror and control:

```bash
scrcpy -s <serial> --max-size 1200 --no-audio
```

## The lockscreen caveat

The pattern/PIN screen is `FLAG_SECURE`, so screenshots and screen capture return black or fail (`SurfaceFlinger: FB is protected: PERMISSION_DENIED`). scrcpy shows a frozen frame there â€” input still works, so the credential can be typed blind. This project does **not** bypass the credential; you still need it to unlock.

## Keywords

scrcpy broken screen Â· screenless android Â· adb_enabled boot script Â· android init rc Â· OrangeFox adb root Â· `/data/misc/adb/adb_keys` Â· Redmi Note 10 Pro sweet M2101K6G Â· FLAG_SECURE screencap Â· locksettings clear Â· `input motionevent` Â· verity disabled vbmeta Â· `sys.usb.config=mtp,adb`

## Disclaimer

Only for devices you own or are authorized to service. Modifying `/system` can break the boot; check verity first.
