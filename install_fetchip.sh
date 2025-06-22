: '
MIT License

Copyright (c) 2025 Sanatani-Dhruv

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
'

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

# Platform detection (silent)
platform=""
os_name="$(uname)"
is_termux=false
use_sudo="sudo"

if [[ "$PREFIX" == *"com.termux"* ]] || grep -qi termux <<< "$HOME"; then
  platform="Termux"
  is_termux=true
  use_sudo=""
elif [[ "$os_name" == "Darwin" ]]; then
  platform="macOS"
elif [[ "$os_name" == "Linux" ]]; then
  platform="Linux"
else
  platform="Unknown"
fi

check_command() {
  local cmd="$1"

  if command -v "$cmd" &>/dev/null; then
    return 0
  fi

  echo "⚠️  '$cmd' is not installed. Detected platform: $platform"
  read -p "Do you want to install '$cmd'? (y/n): " answer
  if [[ "$answer" != "y" && "$answer" != "Y" ]]; then
    echo "❌ '$cmd' is required. Exiting."
    exit 1
  fi

  echo "Installing '$cmd'..."

  if [[ "$platform" == "Termux" ]]; then
    pkg install -y "$cmd"
  elif [[ "$platform" == "Linux" ]]; then
    if command -v apt &>/dev/null; then
      $use_sudo apt update && $use_sudo apt install -y "$cmd"
    elif command -v dnf &>/dev/null; then
      $use_sudo dnf install -y "$cmd"
    elif command -v pacman &>/dev/null; then
      $use_sudo pacman -Sy --noconfirm "$cmd"
    else
      echo "❌ Unsupported Linux package manager. Please install '$cmd' manually."
      exit 1
    fi
  elif [[ "$platform" == "macOS" ]]; then
    if command -v brew &>/dev/null; then
      brew install "$cmd"
    else
      echo "❌ Homebrew not found. Please install Homebrew first: https://brew.sh/"
      exit 1
    fi
  else
    echo "❌ Unknown platform. Please install '$cmd' manually."
    exit 1
  fi
}

# Check essential commands with prompt
check_command curl
check_command jq

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

print_history_table() {
  if [[ ! -s "$log_file" ]]; then
    echo "ℹ️ No lookup history found."
    return
  fi

  # Print header
  printf "\n📜 Lookup History:\n"
  printf "%-20s | %-39s | %-20s\n" "Timestamp" "IP Address" "Location / Org"
  printf -- "---------------------+-----------------------------------------+----------------------\n"

  while IFS='|' read -r ts ip locorg; do
    ts_trimmed=$(echo "$ts" | xargs)
    ip_trimmed=$(echo "$ip" | xargs)
    locorg_trimmed=$(echo "$locorg" | xargs)
    printf "%-20s | %-39s | %-20s\n" "$ts_trimmed" "$ip_trimmed" "$locorg_trimmed"
  done < "$log_file"
  echo ""
}

# Show history
if [[ "$target" == "history" ]]; then
  print_history_table
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
    echo "📜 No history file exists."
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
  echo "🌐 Your Public IPs:"
  echo "IPv4: $(curl -s https://api.ipify.org)"
  echo "IPv6: $(curl -s https://api6.ipify.org)"
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
  echo "$(curl -s https://api.ipify.org)"
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
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"
  export PATH="$HOME/.local/bin:$PATH"
  echo "📎 Added ~/.local/bin to PATH."

  # Auto-source if interactive
  if [[ $- == *i* ]]; then
    [[ -f "$HOME/.bashrc" ]] && source "$HOME/.bashrc"
    [[ -f "$HOME/.zshrc" ]] && source "$HOME/.zshrc"
  fi
fi

echo "✅ 'fetchip' installed!"
echo "👉 You can now run: fetchip my -a -m"
