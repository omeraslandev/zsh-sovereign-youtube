# 🚀 zsh-sovereign-youtube

> **UNIX Felsefesi İle Hafif, Reklamsız ve Terminal Odaklı YouTube Mimarisi**

Ağır web arayüzleri, algoritma manipülasyonları, yüksek RAM tüketimi (Electron) ve reklamlar olmadan; YouTube içeriklerini terminal üzerinden veya yerel bir RSS okuyucu aracılığıyla donanım hızlandırmalı (`VA-API` / `NVDEC`) olarak tüketmek için tasarlanmış bağımsız multimedya sistemi.

---

## ⚡ Öne Çıkan Özellikler

* **Maksimum Kaynak Verimliliği:** FreeTube/Electron gibi 600–800 MB RAM harcayan alternatifler yerine, yalnızca 40–50 MB RAM tüketen GTK tabanlı `liferea` ve `mpv` motoru.
* **Terminal Tabanlı Etkileşim:** `fzf` entegrasyonu ile terminalden anında arama yapma (`yt`) ve arka planda sadece ses/podcast oynatma (`yta`).
* **Tek Tuşla RSS Aboneliği:** `@kullaniciadi` veya URL üzerinden kanal kimliğini saniyeler içinde çözüp RSS akışına dahil eden `ytsub` fonksiyonu.
* **Donanım Hızlandırma & Codec Optimizasyonu (RCA):** `mpv` üzerindeki %210 CPU yükü ve bellek şişmesi sorununun kök neden analizi yapılarak VP9/H.264 codec önceliği ve RAM kotası ile çözülmesi.
* **Zsh Geçmiş Güvenliği (Event Hooks):** `zshaddhistory` çekirdek kancası ve regex filtreleme ile `yt` aramalarının bellek (RAM) ve disk (`.zsh_history`) geçmişine yazılmasının kalıcı olarak engellenmesi.

---

## 📁 Proje Yapısı

```text
zsh-sovereign-youtube/
├── README.md                      # Ana Proje Dokümanı
├── scripts/
│   ├── rss-opener                 # RSS bağlantılarını mpv/tarayıcıya yönlendiren betik
│   └── zshrc-functions.zsh        # yt, yta, ytsub ve zshaddhistory fonksiyonları
└── docs/
    ├── 00-architecture-and-setup.md   # Mimari Detaylar ve Paket Kurulumları
    ├── 01-user-guide.md               # Günlük Kullanım Kılavuzu ve Kısayollar
    ├── 02-rca-mpv-cpu-optimization.md # %210 CPU Kök Neden Analizi (RCA) ve Çözüm
    └── 03-zsh-history-and-hooks.md    # Zsh Geçmiş Mimarisi ve Event Hook Detayları

```

---

## 🛠️ Kurulum

### 1. Bağımlılıkların Yüklenmesi (Ubuntu / Debian)

Sistemdeki temel bağımlılıkları yükleyin ve güncel `yt-dlp` ikili dosyasını indirin:

```bash
# Sistem paketlerini yükleyin
sudo apt update && sudo apt install -y mpv ffmpeg fzf jq liferea curl

# yt-dlp'yi resmi kaynaktan güncel olarak alın
sudo wget [https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp](https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp) -O /usr/local/bin/yt-dlp
sudo chmod a+rx /usr/local/bin/yt-dlp

```

### 2. Reponun Klonlanması ve Entegrasyon

```bash
git clone [https://github.com/kullaniciadi/zsh-sovereign-youtube.git](https://github.com/kullaniciadi/zsh-sovereign-youtube.git)
cd zsh-sovereign-youtube

# 1. Yönlendirici betiği çalıştırılabilir yapın ve yerel ortama taşıyın
chmod +x scripts/rss-opener
mkdir -p ~/.local/bin
cp scripts/rss-opener ~/.local/bin/

# 2. Zsh fonksiyonlarını ~/.zshrc dosyanıza bağlayın
echo "source $(pwd)/scripts/zshrc-functions.zsh" >> ~/.zshrc
source ~/.zshrc

```

### 3. Donanım Hızlandırma & `mpv` Yapılandırması

İşlemciye binen yükü sıfırlamak ve bellek sınırlandırması getirmek için `~/.config/mpv/mpv.conf` dosyasını oluşturun:

```bash
mkdir -p ~/.config/mpv
cat << 'EOF' > ~/.config/mpv/mpv.conf
# Donanım hızlandırmasını güvenli modda zorla (VA-API / NVDEC)
hwdec=auto-safe

# AV1 (av01) akışlarını yoksay; donanım destekli VP9 veya H264 çek
ytdl-format="bestvideo[height<=?1080][vcodec!^=av01]+bestaudio/best"

# RAM önbelleğine kota koy (Sanal/fiziksel belleği 150-200 MB bandına sabitler)
demuxer-max-bytes=150M
demuxer-max-back-bytes=50M
EOF

```

---

## 🎮 Kullanım Özeti

| Komut | Örnek Kullanım | Açıklama |
| :--- | :--- | :--- |
| `yt` | `yt kuantum fiziği` | Fuzzy arama listesi açar, seçileni donanım hızlandırmalı `mpv` ile oynatır. |
| `yta` | `yta lofi hip hop` | Sadece ses akışını alır, arka planda müzik/podcast için idealdir. |
| `ytsub` | `ytsub "@veritasium"` | Kanalın XML beslemesini yakalar ve Liferea RSS okuyucuya ekler. |

---

## 📚 Detaylı Dokümantasyon

Sistem mimarisi, sorun giderme ve teknik analiz raporlarına `docs/` klasöründen erişebilirsiniz:

* 📖 **[Mimari ve Kurulum Detayları (docs/00-architecture-and-setup.md)](https://www.google.com/search?q=docs/00-architecture-and-setup.md)**
* 📖 **[Günlük Kullanım & mpv Kısayolları (docs/01-user-guide.md)](https://www.google.com/search?q=docs/01-user-guide.md)**
* 🔍 **[RCA Raporu: %210 CPU Krizi ve Codec Analizi (docs/02-rca-mpv-cpu-optimization.md)](https://www.google.com/search?q=docs/02-rca-mpv-cpu-optimization.md)**
* 🔒 **[Zsh History Mimarisi & Hook Güvenliği (docs/03-zsh-history-and-hooks.md)](https://www.google.com/search?q=docs/03-zsh-history-and-hooks.md)**


---

## 📄 Lisans

Bu proje [MIT Lisansı](https://www.google.com/search?q=LICENSE) altında sunulmaktadır.
