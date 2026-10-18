# ==============================================================================
# File        : scripts/zshrc-functions.zsh
# Description : Zsh functions & hooks for terminal-driven YouTube environment
# Usage       : Add 'source /path/to/repo/scripts/zshrc-functions.zsh' to ~/.zshrc
# ==============================================================================

# 1. Terminalden fuzzy video arama ve mpv ile oynatma[cite: 12]
yt() {
    local query="$*"
    local video
    video=$(yt-dlp --default-search "ytsearch20" --flat-playlist --print "%(title)s === %(url)s" "$query" 2>/dev/null | fzf --with-nth=1 --delimiter=" ===")
    if [ -n "$video" ]; then
        local url=$(echo "$video" | awk -F' === ' '{print $2}')
        mpv "$url"
    fi
}

# 2. Terminalden sadece ses (arka plan müzik/podcast) oynatma[cite: 12]
yta() {
    local query="$*"
    local video
    video=$(yt-dlp --default-search "ytsearch20" --flat-playlist --print "%(title)s === %(url)s" "$query" 2>/dev/null | fzf --with-nth=1 --delimiter=" ===")
    if [ -n "$video" ]; then
        local url=$(echo "$video" | awk -F' === ' '{print $2}')
        mpv --no-video "$url"
    fi
}

# 3. YouTube kanal beslemesini Liferea RSS okuyucusuna bağlama[cite: 12]
ytsub() {
    if [ -z "$1" ]; then
        echo "Kullanım: ytsub <@kanaladi veya kanal URL'si>"
        return 1
    fi
    echo "Kanal RSS beslemesi çözülüyor..."
    
    # 1. Öncelik: HTML kodundan hızlı XML besleme tespiti[cite: 12]
    local feed_url
    feed_url=$(curl -sL -A "Mozilla/5.0" "$1" | grep -o 'https://www.youtube.com/feeds/videos.xml?channel_id=[^"&]*' | head -n 1)
    
    # 2. Öncelik: Bulunamazsa yt-dlp ile channel_id tespiti[cite: 12]
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

# 4. Zsh Çekirdek Kancası: 'yt' komutlarının geçmişe kaydolmasını engelleme[cite: 9]
zshaddhistory() {
    emulate -L zsh
    if [[ $1 =~ '^[[:space:]]*yt' ]]; then
        return 1  # Bellek ve disk geçmişine yazma[cite: 9]
    fi
    return 0      # Diğer tüm komutları standart kaydet[cite: 9]
}
