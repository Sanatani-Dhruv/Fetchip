#!/bin/bash

echo "🔧 Installing 'fetchip' CLI tool..."

# Cleanup old version
rm -f ~/.local/bin/fetchip

# Ensure ~/.local/bin exists
mkdir -p ~/.local/bin

# Write fetchip script
cat > ~/.local/bin/fetchip << 'EOL'
#!/bin/bash

log_file="$HOME/.fetchip_history.log"
timestamp=$(date '+%Y-%m-%d %H:%M:%S')

# Parse flags and args
show_all=false
multi=false
target=""
show_help=false

for arg in "$@"; do
  case $arg in
    -a) show_all=true ;;
    -m) multi=true ;;
    my) target="my" ;;
    -h|--help) show_help=true ;;
    history) target="history" ;;
    clear) target="clear" ;;
    update|-u|--update) target="update" ;;
    uninstall) target="uninstall" ;;
    *) [[ -z "$target" && "$arg" != "-a" && "$arg" != "-m" ]] && target="$arg" ;;
  esac
done

# Detect platform for package management
detect_platform() {
  if [[ -n "$PREFIX" && "$PREFIX" == *"/data/data"* ]]; then
    echo "termux"
  elif [[ "$(uname)" == "Darwin" ]]; then
    echo "macos"
  elif [[ -f /etc/alpine-release ]]; then
    echo "alpine"
  elif [[ -f /etc/debian_version ]]; then
    echo "debian"
  elif [[ -f /etc/arch-release ]]; then
    echo "arch"
  elif [[ -f /etc/fedora-release ]]; then
    echo "fedora"
  elif [[ -f /etc/void-release ]]; then
    echo "void"
  elif [[ -f /etc/redhat-release ]]; then
    echo "rhel"
  elif command -v nix-env >/dev/null 2>&1; then
    echo "nixos"
  elif [[ "$(uname)" == "FreeBSD" ]]; then
    echo "freebsd"
  else
    echo "unknown"
  fi
}

# Install package if not found
install_package() {
  local cmd=$1
  local pkg=$2
  local platform=$(detect_platform)

  if command -v "$cmd" &>/dev/null; then
    return 0
  fi

  echo "⚠️ '$cmd' is required but not installed. Attempting installation..."

  case "$platform" in
    alpine)
      apk add --no-cache "$pkg"
      ;;
    debian)
      if command -v sudo &>/dev/null; then
        sudo apt update && sudo apt install -y "$pkg"
      else
        apt update && apt install -y "$pkg"
      fi
      ;;
    arch)
      sudo pacman -Sy --noconfirm "$pkg"
      ;;
    fedora|rhel)
      sudo dnf install -y "$pkg" || sudo yum install -y "$pkg"
      ;;
    void)
      sudo xbps-install -Sy "$pkg"
      ;;
    termux)
      pkg install -y "$pkg"
      ;;
    macos)
      brew install "$pkg"
      ;;
    nixos)
      echo "⚠️ Detected NixOS. Please run manually: nix-env -iA nixpkgs.$pkg"
      exit 1
      ;;
    freebsd)
      sudo pkg install -y "$pkg"
      ;;
    *)
      echo "❌ Unknown platform. Please install '$pkg' manually."
      exit 1
      ;;
  esac
}

install_package curl curl
install_package jq jq


# Update command
if [[ "$target" == "update" ]]; then
  echo "🔄 Updating fetchip..."
  bash <(curl -s https://raw.githubusercontent.com/Sanatani-Dhruv/fetchip/main/install_fetchip.sh)
  exit 0
fi

# Uninstall command
if [[ "$target" == "uninstall" ]]; then
  remove_all=false
  auto_yes=false

  for arg in "$@"; do
    [[ "$arg" == "-e" ]] && remove_all=true
    [[ "$arg" == "-y" ]] && auto_yes=true
  done

  echo "⚠️ This will uninstall 'fetchip'."
  [[ "$remove_all" == true ]] && echo "📛 Also set to remove history file."

  if [[ "$auto_yes" != true ]]; then
    read -p "Are you sure? (y/n): " confirm
    [[ "$confirm" != "y" && "$confirm" != "Y" ]] && {
      echo "❌ Uninstall cancelled."
      exit 0
    }
  fi

  rm -f ~/.local/bin/fetchip
  echo "🗑️ Removed fetchip CLI from ~/.local/bin"

  if [[ "$remove_all" == true ]]; then
    rm -f "$log_file"
    echo "🗑️ Removed history log: $log_file"
  fi

  echo "✅ Uninstall complete."
  exit 0
fi

# Help
if [[ "$show_help" == true ]]; then
  echo "📘 Usage: fetchip [my|<IP>|history|clear|update|uninstall] [-a] [-m]"
  echo ""
  echo "COMMANDS:"
  echo "  fetchip                  Show your current public IP"
  echo "  fetchip my               Show both IPv4 and IPv6"
  echo "  fetchip my -a            Show full info from ipinfo.io"
  echo "  fetchip my -a -m         Show info from multiple APIs"
  echo "  fetchip <ip>             Just echo the IP"
  echo "  fetchip <ip> -a          Show full info from ipinfo.io"
  echo "  fetchip <ip> -a -m       Show info from multiple APIs"
  echo "  fetchip history          Show IP lookup history"
  echo "  fetchip clear            Clear history (asks for confirmation)"
  echo "  fetchip update (-u)      Update this script"
  echo "  fetchip uninstall [-e]   Uninstall tool. Use -e to also remove history"
  echo "                           Use -y to skip confirmation"
  echo ""
  echo "OPTIONS:"
  echo "  -a    Show full details"
  echo "  -m    Use multiple IP lookup sources"
  exit 0
fi

# Fetch from multiple APIs
fetch_from_all_sources() {
  local ip="$1"
  echo "🔎 Multi-source info for IP: $ip"
  echo "--------------------------------------"

  echo "📡 ipinfo.io:"
  curl -s "https://ipinfo.io/$ip/json" | jq .

  echo -e "\n📡 ip-api.com:"
  curl -s "http://ip-api.com/json/$ip" | jq .

  echo -e "\n📡 ipwho.is:"
  curl -s "https://ipwho.is/$ip" | jq .

  echo -e "\n📡 ipapi.co:"
  curl -s "https://ipapi.co/$ip/json" | jq .
}

# Show history
if [[ "$target" == "history" ]]; then
  if [[ -s "$log_file" ]]; then
    echo -e "Timestamp\t\t\tIP Address\tLocation\t\tOrganization"
    echo "-------------------------------------------------------------------------------"
    column -t -s '|' <(sed 's/|/\t/g' "$log_file")
  else
    echo "ℹ️ No lookup history found."
  fi
  exit 0
fi

# Clear history
if [[ "$target" == "clear" ]]; then
  if [[ -f "$log_file" ]]; then
    read -p "⚠️ Are you sure you want to clear history? (y/n): " confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
      rm -f "$log_file"
      echo "✅ History cleared."
    else
      echo "❌ Cancelled. History not cleared."
    fi
  else
    echo "ℹ️ No history file exists."
  fi
  exit 0
fi

# fetchip my -a -m
if [[ "$target" == "my" && "$show_all" == true ]]; then
  ipv4=$(curl -s https://api.ipify.org)
  ipv6=$(curl -s https://api6.ipify.org)

  if [[ "$multi" == true ]]; then
    [[ -n "$ipv4" ]] && { echo -e "\n🔍 IPv4 ($ipv4):"; fetch_from_all_sources "$ipv4"; }
    [[ -n "$ipv6" ]] && { echo -e "\n🔍 IPv6 ($ipv6):"; fetch_from_all_sources "$ipv6"; }
  else
    [[ -n "$ipv4" ]] && {
      echo "🔍 IPv4 ($ipv4):"
      info=$(curl -s ipinfo.io/$ipv4)
      echo "$info" | jq .
      city=$(echo "$info" | jq -r '.city // "Unknown"')
      country=$(echo "$info" | jq -r '.country // "Unknown"')
      org=$(echo "$info" | jq -r '.org // "Unknown"')
      echo "$timestamp | $ipv4 | $city, $country | $org" >> "$log_file"
    }
    [[ -n "$ipv6" ]] && {
      echo "🔍 IPv6 ($ipv6):"
      info=$(curl -s ipinfo.io/$ipv6)
      echo "$info" | jq .
      city=$(echo "$info" | jq -r '.city // "Unknown"')
      country=$(echo "$info" | jq -r '.country // "Unknown"')
      org=$(echo "$info" | jq -r '.org // "Unknown"')
      echo "$timestamp | $ipv6 | $city, $country | $org" >> "$log_file"
    }
  fi
  exit 0
fi

# fetchip my (no -a)
if [[ "$target" == "my" ]]; then
  ipv4=$(curl -s https://api.ipify.org)
  ipv6=$(curl -s https://api6.ipify.org)
  echo "🌐 Your Public IPs:"
  echo "IPv4: $ipv4"
  echo "IPv6: $ipv6"
  exit 0
fi

# fetchip <ip> -a -m
if [[ "$target" =~ ^[0-9a-fA-F:.]+$ && "$show_all" == true && "$multi" == true ]]; then
  fetch_from_all_sources "$target"
  exit 0
fi

# fetchip <ip> -a
if [[ "$target" =~ ^[0-9a-fA-F:.]+$ && "$show_all" == true ]]; then
  echo "🔍 Info from ipinfo.io for $target:"
  info=$(curl -s ipinfo.io/$target)
  echo "$info" | jq .
  city=$(echo "$info" | jq -r '.city // "Unknown"')
  country=$(echo "$info" | jq -r '.country // "Unknown"')
  org=$(echo "$info" | jq -r '.org // "Unknown"')
  echo "$timestamp | $target | $city, $country | $org" >> "$log_file"
  exit 0
fi

# fetchip <ip>
if [[ "$target" =~ ^[0-9a-fA-F:.]+$ ]]; then
  echo "$target"
  exit 0
fi

# fetchip (no args)
if [[ -z "$target" ]]; then
  ipv4=$(curl -s https://api.ipify.org)
  echo "$ipv4"
  exit 0
fi

# fallback
echo "❌ Unknown command. Try: fetchip -h"
exit 1
EOL

# Make it executable
chmod +x ~/.local/bin/fetchip

# Add to PATH safely if not already
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
  if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.bashrc" 2>/dev/null; then
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
fi

if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.zshrc" 2>/dev/null; then
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"
fi

  export PATH="$HOME/.local/bin:$PATH"
  echo "📎 Added ~/.local/bin to PATH."

  # Auto-source if interactive
  if [[ $- == *i* ]]; then
    [[ -f "$HOME/.bashrc" ]] && source "$HOME/.bashrc"
    [[ -f "$HOME/.zshrc" ]] && source "$HOME/.zshrc"
  fi
fi

echo "✅ 'fetchip' installed!"
echo "👉 Run: fetchip my -a -m"
echo "🔁 If fetchip is not found in new terminals, run: "
echo "source ~/.bashrc "
echo "or"
echo "source ~/.zshrc"
