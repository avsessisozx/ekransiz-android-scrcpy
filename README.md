# Screenless Android → PC over adb + scrcpy

How to regain control of an Android phone whose display is physically gone — from a PC, over USB, with **adb** and **scrcpy** — on a device whose ROM keeps disabling USB debugging at boot.

**Tested on:** Xiaomi Redmi Note 10 Pro (`sweet` / `M2101K6G`), OrangeFox R12.1_3, Android 13 (`TQ3A.230901.001.B1`, userdebug), verity disabled (`vbmeta flags=0x3`).

g��� **Full write-up:** [English](https://avsessisozx.github.io/ekransiz-android-scrcpy/) · [Türkçe](https://avsessisozx.github.io/ekransiz-android-scrcpy/tr/)

---

## The short version

1. Boot **OrangeFox recovery** (Power + Volume Up). Recovery adbd runs with `ro.adb.secure=0`, so you get a root shell.
2. Check that verity is off before touching `/system` (`avbctl get-verity`).
3. Pre-seed the PC key into `/data/misc/adb/adb_keys` (`system:shell`, `0640`, label `adb_keys_file`).
4. Editing `adb_enabled` in `settings_global.xml` **does not survive boot** — SettingsProvider rewrites the file and the value reverts to `0`.
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

## How this differs from existing tools

[Vighnesh2514/screenless-android](https://github.com/Vighnesh2514/screenless-android) (MIT) is the polished, general-purpose option: one-click launcher, USB/Wi‑Fi switching, a no-admin Windows install, tuning and an agent. It assumes **USB debugging is already on** and that the phone can accept a new key (tap “Allow” once). If that is your case, use it — it is the better tool for that job.

This repo covers the opposite case:

- the ROM **resets `adb_enabled` on every boot** (row id churn: 39969 → 60862 → 60864);
- there is **no usable display**, so the “Allow” dialog can never be confirmed;
- there is **no Magisk**, so the fix is an init script in `/system/etc/init` that runs at `sys.boot_completed`.

No code from that project is used here. Both build on Google's adb and Genymobile's scrcpy.
## The lockscreen caveat

The pattern/PIN screen is `FLAG_SECURE`, so screenshots and screen capture return black or fail (`SurfaceFlinger: FB is protected: PERMISSION_DENIED`). scrcpy shows a frozen frame there — input still works, so the credential can be typed blind. This project does **not** bypass the credential; you still need it to unlock.

## Keywords

scrcpy broken screen · screenless android · adb_enabled boot script · android init rc · OrangeFox adb root · `/data/misc/adb/adb_keys` · Redmi Note 10 Pro sweet M2101K6G · FLAG_SECURE screencap · locksettings clear · `input motionevent` · verity disabled vbmeta · `sys.usb.config=mtp,adb`

## Disclaimer

Only for devices you own or are authorized to service. Modifying `/system` can break the boot; check verity first.
