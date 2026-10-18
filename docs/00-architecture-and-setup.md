# Ubuntu 24.04 Üzerinde Hafif, Reklamsız ve Bağımsız YouTube Mimarisi

Bu kılavuz; ağır web arayüzleri, algoritma manipülasyonu ve reklamlar olmadan YouTube içeriklerini terminalden veya yerel bir RSS okuyucu üzerinden donanım hızlandırmalı olarak tüketmek için kurulan sistem mimarisini belgeler.

---

## 1. Mimari Genel Bakış ve Tercih Sebepleri

Sistem, UNIX felsefesine uygun olarak her biri tek bir işi mükemmel yapan hafif araçların birbirine bağlanmasıyla kurgulanmıştır:

* **Oynatma Motoru (`mpv` & `ffmpeg`):** Tarayıcı yükünü ortadan kaldırır, GPU donanım hızlandırmasını doğrudan kullanarak minimum CPU/RAM harcar.


* **Ayrıştırıcı (`yt-dlp`):** Google API anahtarına ihtiyaç duymadan arama sonuçlarını, kanal kimliklerini ve medya akışlarını çözer.


* **Arayüz & Akış (`liferea`):** GTK tabanlı yerel RSS istemcisi; arka planda yalnızca 40–50 MB RAM tüketir (FreeTube gibi 600–800 MB RAM harcayan Electron uygulamalarına karşı tercih edilmiştir).


* **Arama & Etkileşim (`fzf` & `zsh`):** Terminal üzerinden interaktif fuzzy arama sağlar.


* **Köprü Betikler:** Liferea'daki tıklamaları doğrudan `mpv`'ye yönlendirir ve `@kullaniciadi` formatındaki YouTube kanallarını tek tuşla RSS beslemesine çevirir.



---

## 2. Paket ve Bağımlılık Kurulumları

Ubuntu 24.04 LTS üzerinde `universe` deposu etkinleştirilerek çekirdek paketler ve bağımsız ikili dosyalar kuruldu:

```bash
# 1. Depoları genişlet ve sistemi güncelle[cite: 1]
sudo add-apt-repository universe
sudo apt update && sudo apt upgrade -y

# 2. Medya oynatıcı, arama ve RSS araçlarını yükle[cite: 1]
sudo apt install -y mpv ffmpeg fzf jq liferea

# 3. yt-dlp'yi dağıtım deposu yerine doğrudan en güncel resmi kaynaktan al[cite: 1]
sudo wget https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -O /usr/local/bin/yt-dlp
sudo chmod a+rx /usr/local/bin/yt-dlp

```

---

## 3. Bağlantı Yönlendirici Betik (`rss-opener`)

Liferea varsayılan olarak bağlantıları dahili tarayıcısında açmaya çalışır. YouTube bağlantılarını yakalayıp `mpv`'ye, diğer bağlantıları ise web tarayıcısına fırlatan yönlendirici hazırlandı:

```bash
mkdir -p ~/.local/bin
cat << 'EOF' > ~/.local/bin/rss-opener
#!/usr/bin/env bash

TARGET="$1"

# YouTube video/kanal bağlantısı kontrolü
if [[ "$TARGET" =~ (youtube\.com|youtu\.be) ]]; then
    # Arka planda donanım hızlandırmalı oynatıcıyı tetikle
    mpv "$TARGET" >/dev/null 2>&1 &
else
    # Açıklamalardaki harici linkleri varsayılan web tarayıcısında aç
    xdg-open "$TARGET" >/dev/null 2>&1 &
fi
EOF

chmod +x ~/.local/bin/rss-opener

```

---

## 4. Liferea Yapılandırması

Liferea'nın yönlendirici betiği kullanabilmesi için arayüz tercihi yapıldı:

1. Terminalden `liferea &` komutuyla uygulama açıldı.


2. **Araçlar (Tools) > Tercihler (Preferences) > Tarayıcı (Browser)** sekmesine gidildi.


3. Tarayıcı seçeneği **"Manuel / Özel Tarayıcı Komutu"** olarak işaretlendi.


4. Komut alanına şu değer girildi:


```text
/home/omeraslandev/.local/bin/rss-opener %s

```



---

## 5. Terminal Fonksiyonları (`~/.zshrc`)

Abonelik ekleme, terminalden video arama ve müzik/podcast oynatma işlevlerini otomatikleştiren fonksiyonlar `~/.zshrc` dosyasının sonuna eklendi:

```bash
# -------------------------------------------------------------
# YouTube & Medya Yönetim Fonksiyonları
# -------------------------------------------------------------

# 1. Terminalden fuzzy video arama ve doğrudan mpv ile izleme[cite: 1]
yt() {
    local query="$*"
    local video
    video=$(yt-dlp --default-search "ytsearch20" --flat-playlist --print "%(title)s === %(url)s" "$query" 2>/dev/null | fzf --with-nth=1 --delimiter=" ===")
    if [ -n "$video" ]; then
        local url=$(echo "$video" | awk -F' === ' '{print $2}')
        mpv "$url"
    fi
}

# 2. Terminalden sadece ses (arka plan podcast/müzik) oynatma[cite: 1]
yta() {
    local query="$*"
    local video
    video=$(yt-dlp --default-search "ytsearch20" --flat-playlist --print "%(title)s === %(url)s" "$query" 2>/dev/null | fzf --with-nth=1 --delimiter=" ===")
    if [ -n "$video" ]; then
        local url=$(echo "$video" | awk -F' === ' '{print $2}')
        mpv --no-video "$url"
    fi
}

# 3. YouTube kanalını saniyeler içinde Liferea beslemesine ekleme
ytsub() {
    if [ -z "$1" ]; then
        echo "Kullanım: ytsub <@kanaladi veya kanal URL'si>"
        return 1
    fi
    echo "Kanal bilgisi çözülüyor..."
    
    # 1. Öncelik: HTML başlığından XML beslemesini 1 saniyede yakalar
    local feed_url
    feed_url=$(curl -sL -A "Mozilla/5.0" "$1" | grep -o 'https://www.youtube.com/feeds/videos.xml?channel_id=[^"&]*' | head -n 1)
    
    # 2. Öncelik: Bulunamazsa yt-dlp ile tek video üzerinden channel_id çeker
    if [ -z "$feed_url" ]; then
        local cid
        cid=$(yt-dlp --flat-playlist --playlist-items 1 --print channel_id "$1" 2>/dev/null | head -n 1)
        [ -n "$cid" ] && feed_url="https://www.youtube.com/feeds/videos.xml?channel_id=$cid"
    fi

    if [ -n "$feed_url" ]; then
        echo "Besleme hazır: $feed_url"
        liferea --add-feed "$feed_url" >/dev/null 2>&1 &
    else
        echo "Hata: Kanal beslemesi bulunamadı. Bağlantıyı kontrol edin."
        return 1
    fi
}

```

Kabuk oturumunu güncellemek için çalıştırılan komut:

```bash
source ~/.zshrc

```

---

## 6. Denenip Temizlenen Alternatifler (Neden Elendi?)

Kurulum sürecinde alternatifler test edilmiş ve gereksiz bağımlılık bırakılmadan sistemden arındırılmıştır:

* **Newsboat:** Ubuntu 24.04 depolarında yer almayan ve terk edilmiş olan `stfl` kütüphanesine bağımlı olduğu için kaynak koddan derlenemedi. Yapılandırma artıkları ve derleme araçları temizlendi.


* **ytfzf:** YouTube'un bot ve kazıma korumalarına doğrudan takıldığı için kaldırıldı.


* **FreeTube:** Electron tabanlı olması sebebiyle 600–800 MB RAM tüketimi getirdiğinden ve sistemdeki bağımsız UNIX yapısı tüm ihtiyacı karşıladığından dolayı kurulumundan vazgeçildi.



---

## 7. Kullanım Kılavuzu

| Görev | Komut | Açıklama |
| :--- | :--- | :--- |
| **Kanala Abone Ol** | `ytsub "https://www.youtube.com/@veritasium"` | Kanal kimliğini anında çözer ve Liferea'ya ekleme penceresi açar. |
| **Terminalden Video Ara** | `yt kuantum fiziği belgeseli` | İlk 20 sonucu interaktif listeler, seçileni doğrudan mpv ile açar. |
| **Sadece Ses Dinle** | `yta lofi hip hop radio` | Görüntü penceresi açmadan sesi arka planda akıtır. |
| **RSS Okuyucuyu Aç** | `liferea &` | Kanal beslemelerini, video kapaklarını ve yeni yüklenenleri listeler. |
| **Ayrıştırıcıyı Güncelle** | `sudo yt-dlp -U` | YouTube değişiklik yaptığında oynatma motorunu günceller. |