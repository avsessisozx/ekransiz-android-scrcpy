# Ekranı Olmayan Android → PC (adb + scrcpy)

Fiziksel ekranı sökülmüş bir Android telefonu PC'den, USB üzerinden **adb** + **scrcpy** ile kontrol etme rehberi — ROM her açılışta USB hata ayıklamayı kapatsa bile.

**Test edilen cihaz:** Xiaomi Redmi Note 10 Pro (`sweet` / `M2101K6G`), OrangeFox R12.1_3, Android 13 (`TQ3A.230901.001.B1`, userdebug), verity kapalı (`vbmeta flags=0x3`).

g��� **Makale:** [Türkçe](https://avsessisozx.github.io/ekransiz-android-scrcpy/tr/) · [English](https://avsessisozx.github.io/ekransiz-android-scrcpy/)

---

## Kısa özet

1. **OrangeFox recovery**'ye gir (Güç + Ses Açma). Recovery adbd'si `ro.adb.secure=0` ile çalışır; root shell alırsın.
2. `/system`'e dokunmadan önce verity'nin kapalı olduğunu doğrula (`avbctl get-verity`).
3. PC anahtarını `/data/misc/adb/adb_keys` dosyasına yaz (`system:shell`, `0640`, etiket `adb_keys_file`).
4. `settings_global.xml` içinde `adb_enabled` düzenlemesi **açılışta kalıcı olmaz** — SettingsProvider dosyayı yeniden yazar, değer `0`'a döner.
5. Çözüm: `sys.boot_completed` anında çalışan bir **init script**:

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
7. Görüntü ve kontrol:

```bash
scrcpy -s <seri-no> --max-size 1200 --no-audio
```

## Kilit ekranı notu

Desen/PIN ekranı `FLAG_SECURE`'dır; ekran görüntüsü siyah döner veya başarısız olur (`SurfaceFlinger: FB is protected: PERMISSION_DENIED`). scrcpy o ekranda donar — ama girdi çalışır, kimlik bilgisi körlemesine girilebilir. Bu proje kimlik bilgisini **atlamaz**; kilidi açmak için yine desen/PIN gerekir.

## Anahtar kelimeler

ekranı kırık telefon scrcpy · ekranı olmayan android · adb_enabled boot script · android init rc · OrangeFox adb root · `/data/misc/adb/adb_keys` · Redmi Note 10 Pro sweet M2101K6G · FLAG_SECURE screencap · locksettings clear desen · `input motionevent` · verity disabled vbmeta · `sys.usb.config=mtp,adb`

## Uyarı

Yalnızca sahibi olduğunuz veya yetkili olduğunuz cihazlarda kullanın. `/system` değişikliği boot'u bozabilir; önce verity'yi kontrol edin.
