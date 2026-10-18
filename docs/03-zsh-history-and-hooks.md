Bu dokümantasyon, Zsh kabuğunda `yt` ile başlayan komutların hem mevcut geçmişten (RAM ve disk) güvenli bir şekilde silinmesi hem de `zshaddhistory` kancası ile gelecekte geçmişe yazılmasının kalıcı olarak engellenmesi sürecini kapsar.

---

## 1. Zsh Geçmiş (History) Mimarisi ve Problem

Standart dosya düzenleyicileriyle (`nano`, `vim` vb.) `~/.zsh_history` dosyasını düzenlemek çoğu zaman işe yaramaz. Bunun nedeni Zsh'in iki katmanlı geçmiş yönetimidir:

1. **Bellek (RAM) Katmanı:** Terminal oturumu açıkken girilen komutlar önce o oturumun RAM belleğindeki geçmiş listesine yazılır.
2. **Kalıcı Depolama (Disk) Katmanı:** Komutlar `HISTFILE` (genellikle `~/.zsh_history`) dosyasında tutulur.

Yalnızca dosyayı düzenleyip terminali kapattığınızda, Zsh belleğindeki geçmişi diske geri yazar ve sildiğinizi sandığınız komutlar dosyaya geri döner. Bu nedenle temizlik işlemi hem RAM'i hem de diski senkronize şekilde hedeflemelidir.

---

## 2. Mevcut Geçmişin Temizlenmesi

Mevcut oturumdaki ve diskteki `yt` girdilerini temizlemek için işletilen komut zinciri ve teknik detayları:

```zsh
# 1. Bellekteki oturum geçmişini diske yaz
fc -W

# 2. Dosyanın emniyet yedeğini oluştur
cp "${HISTFILE:-$HOME/.zsh_history}" "${HISTFILE:-$HOME/.zsh_history}.bak"

# 3. 'yt' ile başlayan kayıtları filtrele ve dosyaya yeniden yaz
grep -avE '^(: [0-9]+:[0-9]+;)?[[:space:]]*yt' "${HISTFILE:-$HOME/.zsh_history}.bak" > "${HISTFILE:-$HOME/.zsh_history}"

# 4. Belleği sıfırla ve temizlenen dosyayı belleğe geri oku
HISTSIZE=0; HISTSIZE=10000; fc -R

# 5. Emniyet yedeğini sil
rm "${HISTFILE:-$HOME/.zsh_history}.bak"

```

### Komutların Teknik Analizi

* **`fc -W` (Fix Command - Write):** Aktif terminal penceresinde henüz diske yazılmamış komutları `HISTFILE` dosyasına anında döker. Temizliğe başlamadan önce diski güncel hale getirir.
* **`${HISTFILE:-$HOME/.zsh_history}`:** Değişken atama korumasıdır. Sistemde `$HISTFILE` ortam değişkeni tanımlıysa onu kullanır; tanımsızsa varsayılan olarak `$HOME/.zsh_history` yolunu alır.
* **`grep` Parametreleri ve Düzenli İfade (Regex):**
* `-a` (*text*): Geçmiş dosyasında bulunabilecek ikili (binary) veya bozuk karakterleri düz metin gibi işler; dosyanın kesilmesini engeller.
* `-v` (*invert match*): Kalıpla **eşleşmeyen** satırları ekrana basar (eşleşenleri eler).
* `-E` (*extended regexp*): Gelişmiş düzenli ifadeleri aktif eder.
* `'^(: [0-9]+:[0-9]+;)?[[:space:]]*yt'`:
* `^(: [0-9]+:[0-9]+;)?`: Zsh'in `EXTENDED_HISTORY` ayarı açıksa satır başına eklenen `: 1710000000:0;` biçimindeki zaman damgasını yakalar (isteğe bağlıdır, yoksa da eşleşir).
* `[[:space:]]*`: Komuttan önce yanlışlıkla bırakılmış olabilecek boşluk veya tab karakterlerini kapsar.
* `yt`: Komutun `yt` ile başladığını garanti eder.




* **`HISTSIZE=0; HISTSIZE=10000; fc -R`:**
* `HISTSIZE=0`: Mevcut terminal oturumunun RAM'indeki geçmiş önbelleğini anında boşaltır.
* `HISTSIZE=10000`: Boyutu tekrar standart sınırına çeker.
* `fc -R` (*read*): Az önce filtrelenen temiz diski RAM'e yeniden okur. Terminali kapatıp açma ihtiyacını ortadan kaldırır.


* **`rm "${HISTFILE:-$HOME/.zsh_history}.bak"`:** Filtreleme başarıyla tamamlandıktan sonra oluşturulan geçici yedek dosyasını temizler.

---

## 3. Gelecekteki Kayıtların Engellenmesi: `zshaddhistory` Kancası

Temizlik anlıktır; sisteme kalıcı bir filtre eklenmezse girilen ilk yeni `yt` komutu tekrar geçmişe yazılır. Bunu engellemek için Zsh'in çekirdek olay kancası (event hook) olan `zshaddhistory` fonksiyonu `~/.zshrc` dosyasına işlendi:

```zsh
cat << 'EOF' >> ~/.zshrc

# 'yt' ile başlayan komutları history'e yazma
zshaddhistory() {
  emulate -L zsh
  if [[ $1 =~ '^[[:space:]]*yt' ]]; then
    return 1
  fi
  return 0
}
EOF

```

Değişikliklerin oturuma yansıması için dosya yeniden yüklendi:

```zsh
source ~/.zshrc

```

### Fonksiyonun Çalışma Mekanizması

1. **Tetiklenme Zamanı:** Zsh, kullanıcı bir komut yazıp `Enter` tuşuna bastığı anda; komutu çalıştırmadan hemen önce `zshaddhistory` fonksiyonunu çağırır.
2. **Parametre ($1):** Fonksiyona ilk parametre (`$1`) olarak çalıştırılmak üzere olan ham komut satırı iletilir.
3. **`emulate -L zsh`:** Fonksiyonun kendi yerel ortamında saf Zsh kurallarını çalıştırmasını sağlar. Kullanıcının genel konfigürasyonundaki farklı kabuk seçenekleri (regex veya genişletme ayarları) bu fonksiyonun mantığını bozamaz.
4. **Dönüş Değerleri (Return Codes):**
* **`return 1` (Kaydetme):** Eğer komut satırı `^[[:space:]]*yt` kuralına uyuyorsa (başında boşluk olsa dahi `yt` ile başlıyorsa), fonksiyon `1` döner. Bu sinyal Zsh'e *"Bu komutu çalıştır ama ne dahili bellek geçmişine ne de disk dosyasına yazma"* talimatı verir.
* **`return 0` (Kaydet):** Şarta uymayan diğer tüm komutlar için `0` döner ve Zsh komutu standart şekilde geçmişe kaydeder.
