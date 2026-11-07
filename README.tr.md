# EkranÄ± Olmayan Android â†’ PC (adb + scrcpy)

Fiziksel ekranÄ± sÃ¶kÃ¼lmÃ¼ÅŸ bir Android telefonu PC'den, USB Ã¼zerinden **adb** + **scrcpy** ile kontrol etme rehberi â€” ROM her aÃ§Ä±lÄ±ÅŸta USB hata ayÄ±klamayÄ± kapatsa bile.

**Test edilen cihaz:** Xiaomi Redmi Note 10 Pro (`sweet` / `M2101K6G`), OrangeFox R12.1_3, Android 13 (`TQ3A.230901.001.B1`, userdebug), verity kapalÄ± (`vbmeta flags=0x3`).

ğŸ“„ **Makale:** [TÃ¼rkÃ§e](https://avsessisozx.github.io/ekransiz-android-scrcpy/tr/) Â· [English](https://avsessisozx.github.io/ekransiz-android-scrcpy/)

---

## KÄ±sa Ã¶zet

1. **OrangeFox recovery**'ye gir (GÃ¼Ã§ + Ses AÃ§ma). Recovery adbd'si `ro.adb.secure=0` ile Ã§alÄ±ÅŸÄ±r; root shell alÄ±rsÄ±n.
2. `/system`'e dokunmadan Ã¶nce verity'nin kapalÄ± olduÄŸunu doÄŸrula (`avbctl get-verity`).
3. PC anahtarÄ±nÄ± `/data/misc/adb/adb_keys` dosyasÄ±na yaz (`system:shell`, `0640`, etiket `adb_keys_file`).
4. `settings_global.xml` iÃ§inde `adb_enabled` dÃ¼zenlemesi **aÃ§Ä±lÄ±ÅŸta kalÄ±cÄ± olmaz** â€” SettingsProvider dosyayÄ± yeniden yazar, deÄŸer `0`'a dÃ¶ner.
5. Ã‡Ã¶zÃ¼m: `sys.boot_completed` anÄ±nda Ã§alÄ±ÅŸan bir **init script**:

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

6. `chmod` / `chown` / `chcon u:object_r:system_file:s0`, `sync`, reboot. ~20 sn sonra adb geri gelir.
7. GÃ¶rÃ¼ntÃ¼ ve kontrol:

```bash
scrcpy -s <seri-no> --max-size 1200 --no-audio
```

## Kilit ekranÄ± notu

Desen/PIN ekranÄ± `FLAG_SECURE`'dÄ±r; ekran gÃ¶rÃ¼ntÃ¼sÃ¼ siyah dÃ¶ner veya baÅŸarÄ±sÄ±z olur (`SurfaceFlinger: FB is protected: PERMISSION_DENIED`). scrcpy o ekranda donar â€” ama girdi Ã§alÄ±ÅŸÄ±r, kimlik bilgisi kÃ¶rlemesine girilebilir. Bu proje kimlik bilgisini **atlamaz**; kilidi aÃ§mak iÃ§in yine desen/PIN gerekir.

## Anahtar kelimeler

ekranÄ± kÄ±rÄ±k telefon scrcpy Â· ekranÄ± olmayan android Â· adb_enabled boot script Â· android init rc Â· OrangeFox adb root Â· `/data/misc/adb/adb_keys` Â· Redmi Note 10 Pro sweet M2101K6G Â· FLAG_SECURE screencap Â· locksettings clear desen Â· `input motionevent` Â· verity disabled vbmeta Â· `sys.usb.config=mtp,adb`

## UyarÄ±

YalnÄ±zca sahibi olduÄŸunuz veya yetkili olduÄŸunuz cihazlarda kullanÄ±n. `/system` deÄŸiÅŸikliÄŸi boot'u bozabilir; Ã¶nce verity'yi kontrol edin.
