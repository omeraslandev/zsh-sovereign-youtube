# Sorun Çözüm Raporu: `mpv` Aşırı CPU (%210) ve Bellek Şişmesi Krizi

Bu doküman; hafif YouTube altyapısında rastgele bir video açıldığında karşılaşılan aşırı işlemci yükü ve bellek tahsisi krizinin kök neden analizini ve uygulanan kalıcı çözüm adımlarını özetler.

---

## 1. Belirtiler ve İlk Tespitler

Bir video oynatılırken sistemde aniden fanların hızlanması ve kaynak tüketiminin fırlaması üzerine alınan süreç dökümü (`ps aux --sort=-%mem`):

```text
USER         PID %CPU %MEM        VSZ    RSS TTY      STAT START   TIME COMMAND
omerasl+  201818  210  6.0    2809048 480696 pts/0    SLl+ 13:08   0:20 mpv https://youtu.be/...

```

* **Bellek Durumu:** `mpv`, fiziksel olarak **~480 MB RAM (RSS)** tüketirken işletim sisteminden **~2.8 GB sanal bellek (VSZ)** tahsis etti. Sınırsız arabellekleme (demuxer buffer) nedeniyle sanal bellek 3 GB sınırına dayandı.
* **İşlemci Durumu:** **%210 CPU** kullanımı tespit edildi. Oynatıcı, işlemcinin en az iki tam çekirdeğini %100 yükte çalıştırıyordu.

---

## 2. Kök Neden Analizi (Root Cause Analysis)

Terminal üzerinden yapılan donanım taraması (`lspci -k | grep -EA3 'VGA|3D'`):

* **Dahili GPU:** Intel Corporation CometLake-H GT2 [UHD Graphics 630]
* **Harici GPU:** NVIDIA Corporation TU117M [GeForce GTX 1650 Mobile]

### Sorunun Kaynağı: AV1 Codec Uyuşmazlığı

1. **Varsayılan Davranış:** `yt-dlp`, YouTube'dan video çekerken varsayılan olarak en yeni ve yüksek kaliteli format olan **AV1 (`av01`)** akışını seçer.
2. **Donanım Yetersizliği:** Donanımsal AV1 çözme yeteneği Intel tarafında 11. nesil (Tiger Lake) ve üzerinde, NVIDIA tarafında ise RTX 3000 serisi ve üzerinde mevcuttur. Sistemdeki Intel 10. nesil (Comet Lake) ve GTX 1650 (Turing TU117) mimarilerinde donanımsal AV1 çözücü birimi bulunmaz.
3. **Sonuç:** Donanım hızlandırma (`hwdec`) başarısız oldu. `mpv`, 1080p/4K AV1 akışını işlemciye devretti (`dav1d` yazılımsal çözücü). İşlemci kareleri yetiştirmek için tam yüke girdi (%210 CPU), önbellek limitleri tanımlı olmadığı için de bellek şişti.

---

## 3. Uygulanan Çözüm Adımları

Sistemdeki donanımların tam hızlandırıcı desteğine sahip olduğu **VP9** ve **H.264 (AVC)** formatlarına öncelik verilerek AV1 akışları filtrelendi ve bellek tüketimi sınırlandı.

### Adım 1: Donanım Çözme Sürücülerinin Kurulması

Intel grafik yongası için VA-API video hızlandırma kütüphanesi sisteme eklendi:

```bash
sudo apt install -y intel-media-va-driver vainfo

```

### Adım 2: `mpv` Yapılandırma Dosyasının Oluşturulması

Yapılandırma dizini oluşturulup `mpv` motoruna codec ve bellek frenleri eklendi:

```bash
mkdir -p ~/.config/mpv
cat << 'EOF' > ~/.config/mpv/mpv.conf
# 1. Donanım hızlandırmasını güvenli modda zorla (VA-API / NVDEC)
hwdec=auto-safe

# 2. AV1 (av01) akışlarını yoksay; maksimum 1080p VP9 veya H264 çek
ytdl-format="bestvideo[height<=?1080][vcodec!^=av01]+bestaudio/best"

# 3. RAM önbelleğine kota koy (Sanal/fiziksel belleği 150-200 MB bandına sabitler)
demuxer-max-bytes=150M
demuxer-max-back-bytes=50M
EOF

```

---

## 4. Doğrulama ve Elde Edilen Sonuç

Yapılandırma uygulandıktan sonra sistem süreçleri tekrar kontrol edildi:

```text
USER         PID %CPU %MEM        VSZ    RSS TTY      STAT START   TIME COMMAND
omerasl+  189508 54.1 11.2 1518686788 895988 ?        Sl   12:28  23:35 .../brave
omerasl+  162981  0.1  7.1    2470944 573288 ?        Sl   Sep12   0:52 /usr/bin/gnome-software
omerasl+  189054  3.3  4.0   55467332 325584 ?        Sl   12:27   1:27 .../brave
omerasl+  162822  1.0  3.8    4744400 310972 ?        Rsl  Sep12   8:33 /usr/bin/gnome-shell

```

* **Bellek:** `mpv`, sistemin en çok bellek tüketen ilk 5 süreci arasından tamamen düştü (GNOME Shell'in 310 MB seviyesinin altına indi).
* **İşlemci:** Donanım hızlandırma ve VP9/H.264 codec eşleşmesi sayesinde CPU kullanımı %210 seviyesinden tek haneli / %10–20 bandına geriledi.

---

## 5. Teşhis Komutları (Gerektiğinde Kullanılacaklar)

Oynatma anında donanım hızlandırmasını ve kaynak tüketimini teyit etmek için:

* **Oynatıcı İçi Doğrulama:** Video oynarken klavyeden **`i`** tuşuna basıldığında açılan ekranda `Hardware decoding: vaapi` (veya `nvdec`) ve `vcodec: vp9` yazdığı görülür.
* **Süreç Takibi:** Terminalden anlık tüketimi izlemek için:
```bash
ps -C mpv -o %cpu,%mem,vsz,rss,cmd

```