
#!/bin/bash

echo "🔧 Installing 'fetchip' CLI tool..."

# Cleanup old
rm -f ~/.local/bin/fetchip

# Ensure ~/.local/bin exists
mkdir -p ~/.local/bin

# Write the script
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
    *) [[ -z "$target" && "$arg" != "-a" && "$arg" != "-m" ]] && target="$arg" ;;
  esac
done

# Ensure jq is installed
if ! command -v jq &>/dev/null; then
  echo "⚠️  'jq' is required but not installed."
  echo "Choose your OS:"
  echo "1. Linux (Debian/Ubuntu)"
  echo "2. macOS"
  read -p "Select 1 or 2: " choice
  if [[ "$choice" == "1" ]]; then
    sudo apt update && sudo apt install -y jq
  elif [[ "$choice" == "2" ]]; then
    brew install jq
  else
    echo "❌ Invalid choice."
    exit 1
  fi
fi

# Help
if [[ "$show_help" == true ]]; then
  echo "📘 Usage: fetchip [my|<IP>|history|clear] [-a] [-m]"
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
    echo "📜 Lookup History:"
    cat "$log_file"
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
  ipv4=$(curl -s -4 https://ipecho.net/plain)
  ipv6=$(curl -s -6 https://ipecho.net/plain)

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
  echo "🌐 Your Public IPs:"
  echo "IPv4: $(curl -s -4 https://ipecho.net/plain)"
  echo "IPv6: $(curl -s -6 https://ipecho.net/plain)"
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
  echo "$(curl -s https://ipecho.net/plain)"
  exit 0
fi

# fallback
echo "❌ Unknown command. Try: fetchip -h"
exit 1
EOL

chmod +x ~/.local/bin/fetchip

# Add to PATH
if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
  export PATH="$HOME/.local/bin:$PATH"
  echo "📎 Added ~/.local/bin to PATH. Please restart terminal or run: source ~/.bashrc"
fi

echo "✅ 'fetchip' installed!"
echo "👉 Try: fetchip my -a -m"

