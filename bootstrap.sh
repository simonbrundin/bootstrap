#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

LOG_FILE="$HOME/bootstrap.log"
exec > >(tee -a "$LOG_FILE") 2>&1
echo "🚀 Startar bootstrap $(date)"

# --------------------------------------------------------------------------------------------------
# 🧱 INSTALLERA HOMEBREW
# --------------------------------------------------------------------------------------------------

if ! command -v brew &>/dev/null; then
    echo "📦 Installerar Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Detektera brew prefix
if [[ -x "$HOME/.linuxbrew/bin/brew" ]]; then
    BREW_PREFIX="$HOME/.linuxbrew"
elif [[ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
    BREW_PREFIX="/home/linuxbrew/.linuxbrew"
else
    echo "❌ Homebrew inte hittat!" >&2
    exit 1
fi
eval "$($BREW_PREFIX/bin/brew shellenv)"

# Lägg till i .bashrc om inte redan finns
if ! grep -q "brew shellenv" "$HOME/.bashrc"; then
    echo "eval \"\$($BREW_PREFIX/bin/brew shellenv)\"" >> "$HOME/.bashrc"
fi

# --------------------------------------------------------------------------------------------------
# 🔑 SETUP SSH-NYCKLAR FÖR GITHUB
# --------------------------------------------------------------------------------------------------

DEFAULT_NAME="Omarchy"
KEY_NAME="$DEFAULT_NAME"
COMMENT="$(whoami)@$(hostname) (Omarchy $(date +%Y-%m-%d))"

if [[ -z "$KEY_NAME" ]]; then
    echo "❌ Fel: Namn på nyckeln får inte vara tomt!"
    exit 1
fi

SSH_DIR="$HOME/.ssh"
KEY_PATH="$SSH_DIR/$KEY_NAME"
KEY_PUB="$KEY_PATH.pub"

mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

echo "🔎 Kontrollerar om SSH-nyckel '$KEY_NAME' finns..."
if [[ ! -f "$KEY_PATH" ]]; then
    echo "🪄 Genererar ny ed25519 SSH-nyckel..."
    ssh-keygen -t ed25519 -C "$COMMENT" -f "$KEY_PATH" -N "" || {
        echo "❌ Fel: kunde inte generera SSH-nyckel!"
        exit 1
    }
    chmod 600 "$KEY_PATH"
    chmod 644 "$KEY_PUB"
    echo "✅ Nyckel genererad: $KEY_PATH"
else
    echo "✅ SSH-nyckel finns redan: $KEY_PATH"
fi

# Configure SSH to use this key for GitHub
SSH_CONFIG="$SSH_DIR/config"
if ! grep -q "Host github.com" "$SSH_CONFIG" 2>/dev/null; then
    echo "🔧 Konfigurerar SSH för att använda nyckeln för GitHub..."
    {
        echo "Host github.com"
        echo "    HostName github.com"
        echo "    User git"
        echo "    IdentityFile $KEY_PATH"
    } >> "$SSH_CONFIG"
    chmod 600 "$SSH_CONFIG"
fi

if [[ ! -f "$KEY_PUB" ]]; then
    echo "❌ Fel: Kunde inte hitta publik nyckel: $KEY_PUB"
    exit 1
fi
PUBLIC_KEY=$(cat "$KEY_PUB")

echo "🔑 Startar ssh-agent och lägger till nyckel..."
if ! [[ -v SSH_AGENT_PID ]] || [[ -z "$SSH_AGENT_PID" ]] || ! kill -0 "$SSH_AGENT_PID" 2>/dev/null; then
    eval "$(ssh-agent -s)"
fi
ssh-add "$KEY_PATH" || {
    echo "❌ Fel: Kunde inte lägga till nyckel till ssh-agent!"
    exit 1
}

echo "🔧 Försöker lägga till nyckel till GitHub med gh CLI..."
if command -v gh >/dev/null 2>&1; then
    if gh auth status >/dev/null 2>&1; then
        gh ssh-key add "$KEY_PUB" --title "$KEY_NAME" && {
            echo "✅ Nyckel tillagd till GitHub via gh CLI!"
        } || {
            echo "❌ Kunde inte lägga till nyckel via gh CLI. Kontrollera autentisering."
        }
    else
        echo "❌ gh CLI är installerat men du är inte autentiserad. Kör 'gh auth login' först."
    fi
else
    echo "❌ gh CLI är inte installerat. Installera det för automatisk tillägg av nyckel."
fi

echo
echo "📋 Kopiera den här publika nyckeln till GitHub: https://github.com/settings/keys"
echo
echo "$PUBLIC_KEY"
echo

# --------------------------------------------------------------------------------------------------
# 📁 SKAPA REPOS-MAPP
# --------------------------------------------------------------------------------------------------

echo "📂 Skapar katalog för repositories..."
mkdir -p "$HOME/repos"

# --------------------------------------------------------------------------------------------------
# 🧩 KLONA DOTFILES
# --------------------------------------------------------------------------------------------------

if [ -d "$HOME/repos/dotfiles" ]; then
    echo "🔄 Uppdaterar befintliga dotfiles..."
    cd "$HOME/repos/dotfiles" && git pull
else
    echo "⬇️ Klonar dotfiles..."
    git clone git@github.com:simonbrundin/dotfiles.git "$HOME/repos/dotfiles" || {
        echo "❌ Kunde inte klona dotfiles!"
        exit 1
    }
fi

# --------------------------------------------------------------------------------------------------
# 🧠 KLONA SIMON CLI
# --------------------------------------------------------------------------------------------------

if [ -d "$HOME/repos/simon-cli" ]; then
    echo "🔄 Uppdaterar Simon CLI..."
    cd "$HOME/repos/simon-cli" && git pull
else
    echo "⬇️ Klonar Simon CLI..."
    git clone git@github.com:simonbrundin/simon-cli.git "$HOME/repos/simon-cli" || {
        echo "❌ Kunde inte klona Simon CLI!"
        exit 1
    }
fi

# --------------------------------------------------------------------------------------------------
# 🍺 INSTALLERA PAKET VIA BREW
# --------------------------------------------------------------------------------------------------

if [[ -f "$HOME/repos/dotfiles/brew/.Brewfile" ]]; then
    echo "📦 Litar på taps...
"
    # Trust all third-party taps to avoid "untrusted tap" errors
    brew trust arimxyer/tap 2>/dev/null || true
    brew trust arl/arl 2>/dev/null || true
    brew trust boolean-maybe/tap 2>/dev/null || true
    brew trust buildpacks/tap 2>/dev/null || true
    brew trust charmbracelet/tap 2>/dev/null || true
    brew trust controlplaneio-fluxcd/tap 2>/dev/null || true
    brew trust dagger/tap 2>/dev/null || true
    brew trust dotenvx/brew 2>/dev/null || true
    brew trust elio-fm/elio 2>/dev/null || true
    brew trust floatpane/matcha 2>/dev/null || true
    brew trust fluxcd/tap 2>/dev/null || true
    brew trust gromgit/brewtils 2>/dev/null || true
    brew trust hashicorp/tap 2>/dev/null || true
    brew trust marcus/tap 2>/dev/null || true
    brew trust oven-sh/bun 2>/dev/null || true
    brew trust teamookla/speedtest 2>/dev/null || true
    brew trust tilt-dev/tap 2>/dev/null || true
    brew trust vmware-tanzu/buildkit-cli-for-kubectl 2>/dev/null || true
    brew trust antoniorodr/cronboard 2>/dev/null || true
    brew trust loft-sh/tap 2>/dev/null || true
    brew trust retlehs/tap 2>/dev/null || true
    
    echo ""
    echo "📦 Installerar paket via Brew..."
    brew bundle --file="$HOME/repos/dotfiles/brew/.Brewfile"
else
    echo "⚠️ Ingen Brewfile hittades i dotfiles/brew/.Brewfile"
fi

# --------------------------------------------------------------------------------------------------
# 🐚 SÄTT BASH SOM STANDARDSHELL
# --------------------------------------------------------------------------------------------------

BASH_PATH="/bin/bash"
if [[ ! -x "$BASH_PATH" ]]; then
    echo "❌ Bash inte hittat!" >&2
    exit 1
fi

if [[ "$(getent passwd "$USER" | cut -d: -f7)" != "$BASH_PATH" ]]; then
    sudo usermod -s "$BASH_PATH" "$USER"
    echo "✅ Bash är nu standardshell. Starta om terminalen!"
fi

# --------------------------------------------------------------------------------------------------
# 🧷 SÄTT UPP DOTFILES MED STOW
# --------------------------------------------------------------------------------------------------

BACKUP_DIR="$HOME/.dotfiles-backup/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"
cd "$HOME/repos/dotfiles"
for dir in */; do
    stow --verbose "$dir" --target="$HOME" || echo "⚠️ Hoppar över $dir"
done

# --------------------------------------------------------------------------------------------------
# Starta om Chromium för att installera extensions
# --------------------------------------------------------------------------------------------------

# pkill chromium
# chromium &


# --------------------------------------------------------------------------------------------------
# 🎹 KANATA - Tangetbord
# --------------------------------------------------------------------------------------------------

# chmod +x "$HOME/repos/dotfiles/kanata/.config/kanata/fix-privileges.sh"
#if [[ -x "$HOME/repos/dotfiles/kanata/.config/kanata/fix-privileges.sh" ]]; then
#    echo "⚙️  Kör kanata fix-privileges..."
#    bash "$HOME/repos/dotfiles/kanata/.config/kanata/fix-privileges.sh"
#else
#    echo "⚠️  Hittade inte fix-privileges.sh för Kanata."
#fi

# Installera och starta Kanata
chmod +x "$HOME/repos/dotfiles/kanata/.config/kanata/install-kanata.sh"
if [[ -x "$HOME/repos/dotfiles/kanata/.config/kanata/install-kanata.sh" ]]; then
    echo "⚙️  Installerar och startar Kanata..."
    bash "$HOME/repos/dotfiles/kanata/.config/kanata/install-kanata.sh"
else
    echo "⚠️  Hittade inte install-kanata.sh för Kanata."
fi

pkill kanata && sleep 1 && kanata

# --------------------------------------------------------------------------------------------------
# 🫙 DEVPOD - INSTALLERA
# --------------------------------------------------------------------------------------------------

if ! command -v devpod &>/dev/null; then
    curl -L -o devpod "https://github.com/loft-sh/devpod/releases/latest/download/devpod-linux-amd64" && sudo install -c -m 0755 devpod /usr/local/bin && rm -f devpod
fi

# --------------------------------------------------------------------------------------------------
# 📜 SETUP FÖR ATUIN
# --------------------------------------------------------------------------------------------------

mkdir -p "$HOME/.local/share/atuin/"

# echo "Running simon bootstrap via nushell..."
# nu -c "$HOME/repos/simon-cli/simon bootstrap mac"

# --------------------------------------------------------------------------------------------------
# 🚀 Öppna program (endast om inte redan öppna)
# --------------------------------------------------------------------------------------------------

is_window_open() {
    local domain="$1"
    hyprctl clients -j 2>/dev/null | grep -q "\"class\":.*$domain" 
}

launch_if_closed() {
    local url="$1"
    local domain
    domain=$(echo "$url" | sed -E 's|https?://([^/]+).*|\1|' | sed 's/www\.//')
    
    if is_window_open "$domain"; then
        echo "⏭️  Hoppar över $url (redan öppen)"
    else
        echo "📱 Öppnar $url..."
        omarchy-launch-webapp "$url" &
    fi
}

echo "📱 Öppnar standardprogram..."
omarchy-launch-browser &
launch_if_closed "https://www.messenger.com/"
launch_if_closed "https://notion.so/simonbrundin"
launch_if_closed "https://web.telegram.org/k/#@MooniOpenClawBot"
launch_if_closed "https://grok.com"


# --------------------------------------------------------------------------------------------------
# 🔚 SLUT
# --------------------------------------------------------------------------------------------------

echo "✅ Bootstrap klar! Logg: $LOG_FILE"
echo "   Starta om terminalen för att använda Bash."
