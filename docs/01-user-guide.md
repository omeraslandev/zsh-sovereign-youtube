# Bağımsız YouTube Mimarisi: Günlük Kullanım ve Pratik Rehber

Bu kılavuz, kurulan hafif multimedya altyapısını günlük akışınızda en verimli şekilde kullanabilmeniz için hazırlanmış operasyonel el kitabıdır.

---

## 1. Terminalden Video Arama ve İzleme (`yt`)

YouTube ana sayfasına veya arama çubuğuna girmeden doğrudan kabuk üzerinden arama yapıp videoyu başlatır.

**Komut Kullanımı:**

```bash
yt aramak istediğiniz video konusu

```

**Nasıl Çalışır ve Nasıl Yönetilir?**

1. Komutu girdiğinizde arka planda `yt-dlp` ilk 20 video sonucunu başlıklarıyla çeker.
2. Karşınıza etkileşimli **`fzf`** listesi gelir.
3. Klavyeden harf yazarak listeyi filtreleyebilir, **Yukarı/Aşağı Yön Tuşları** ile sonuçlar arasında gezinebilirsiniz.
4. **Enter:** Seçilen videoyu donanım hızlandırmalı olarak doğrudan `mpv` penceresinde başlatır.
5. **Esc** veya **Ctrl + C:** Arama ekranından hiçbir şey oynatmadan çıkar.

---

## 2. Terminalden Arka Planda Müzik / Podcast Dinleme (`yta`)

Çalışırken veya kod yazarken video penceresiyle ekranı bölmeden sadece ses akışını almak için kullanılır.

**Komut Kullanımı:**

```bash
yta lofi hip hop radio
yta roborock s8 inceleme podcast

```

* Ekran penceresi açılmaz; CPU ve RAM tüketimi sıfıra yakın seviyede kalır.
* Terminal üzerinde sadece ses akışı devam eder; durdurmak veya kapatmak için terminalde **`q`** veya **`Ctrl + C`** tuşlamanız yeterlidir.

---

## 3. RSS Akışına Yeni Kanal Ekleme (`ytsub`)

YouTube kanallarını yerel RSS okuyucunuz Liferea'ya tek saniyede bağlar.

**Komut Kullanımı:**

```bash
ytsub "https://www.youtube.com/@KanalAdi"

```

**İşlem Sırası:**

1. Fonksiyon, verilen kanal linkinin kaynak kodundan saniyeler içinde benzersiz `channel_id` değerini yakalar.
2. Liferea'nın besleme ekleme penceresi ekrana gelir ve RSS besleme URL'si otomatik doldurulmuş olur.
3. Çıkan pencerede **Kaydet (Save)** butonuna basmanız yeterlidir. Kanalın en son yüklenen 15 videosu kapak görselleriyle birlikte akışınıza dahil edilir.

---

## 4. Liferea Arayüzü ile Günlük Tüketim

Liferea'yı terminalden `liferea &` komutuyla veya sisteminizin uygulama menüsünden başlatabilirsiniz.

* **Sol Panel:** Takip ettiğiniz kanalların listesi. Kanalları sağ tıklayıp klasörler (ör. *Yazılım*, *Bilim*, *Müzik*) altında toplayabilirsiniz.
* **Orta/Üst Panel:** Seçilen kanalın son yüklenen videoları, yayınlanma tarihleri ve başlıkları.
* **İzleme:** Listeden herhangi bir videonun başlığına çift tıkladığınızda `rss-opener` betiği devreye girer:
* Tarayıcı açılmaz, reklam yüklenmez.
* Doğrudan `mpv` tam ekran/pencere modunda videoyu oynatmaya başlar.


* **Akışı Güncelleme:** Liferea varsayılan olarak belirli aralıklarla yeni videoları çeker; anlık yenilemek isterseniz üst menüdeki **Yenile (F5 veya Ctrl + R)** kısayolunu kullanabilirsiniz.

---

## 5. `mpv` Oynatıcı Kısayol Tablosu

Tarayıcıdaki fare bağımlılığını ortadan kaldıran en pratik `mpv` klavye kısayolları:

| Tuş | Eylem |
| --- | --- |
| **Boşluk (Space)** | Oynat / Duraklat |
| **f** | Tam ekran modunu aç / kapat |
| **Sağ / Sol Ok** | 5 saniye ileri / geri sar |
| **Yukarı / Aşağı Ok** | 1 dakika ileri / geri sar |
| **[ ve ]** | Oynatma hızını %10 düşür / artır (1.1x, 1.2x...) |
| **Backspace** | Oynatma hızını normale (1.0x) sıfırla |
| **9 / 0** | Sesi kıs / artır |
| **m** | Sesi tamamen kapat (Mute) |
| **Shift + q** | Videoyu kapatırken **kaldığın saniyeyi kaydet** (sonraki açılışta devam eder) |
| **q** | Oynatıcıyı doğrudan kapat |

---

## 6. Bakım ve Olası Hata Durumları

YouTube periyodik olarak video akış algoritmalarında değişiklik yapar. Bu tarz durumlarda karşılaşabileceğiniz senaryolar ve çözümleri:

### "Video açılmıyor / yt-dlp hata veriyor"

YouTube arka plan kodlarını değiştirdiğinde `yt-dlp` bağımsız ikili dosyasını tek komutla güncellemeniz gerekir:

```bash
sudo yt-dlp -U

```

### "Liferea linke tıklayınca mpv yerine tarayıcıyı açıyor"

Liferea tercihinin doğru kalıp kalmadığını kontrol edin:

* **Tercihler > Tarayıcı > Manuel Komut:** `/home/omeraslandev/.local/bin/rss-opener %s`

### Kanal Eklerken "Besleme Bulunamadı" Hatası

Verilen URL'nin tam formatta olduğundan emin olun:

* **Hatalı:** `ytsub veritasium`
* **Doğru:** `ytsub "[https://www.youtube.com/@veritasium](https://www.youtube.com/@veritasium)"`