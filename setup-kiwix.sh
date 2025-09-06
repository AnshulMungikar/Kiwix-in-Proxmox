#!/bin/bash

# Require root privileges
if [ "$EUID" -ne 0 ]; then
  echo "❌ Please run this script as root (use sudo)."
  exit 1
fi


# Interactive Kiwix setup script with multiple ZIM support

echo "=============================="
echo "   🚀 Kiwix Server Installer   "
echo "=============================="

# Step 1: Set DNS
echo "== Step 1: Updating nameservers =="
if command -v resolvectl >/dev/null 2>&1; then
  resolvectl dns eth0 8.8.8.8 8.8.4.4
else
  echo "Warning: resolvectl not found. Skipping DNS configuration."
fi


# Step 3: Install dependencies
echo "== Step 3: Installing Kiwix =="
apt install -y kiwix kiwix-tools wget


# Step 4: Ask user for IP and port
DEFAULT_IP=$(hostname -I | awk '{print $1}')
read -p "Enter the IP address to bind Kiwix (default: $DEFAULT_IP): " KIWI_IP
KIWI_IP=${KIWI_IP:-$DEFAULT_IP}

read -p "Enter the port for Kiwix server (default: 8080): " KIWI_PORT
KIWI_PORT=${KIWI_PORT:-8080}


# Step 5: Choose ZIM files
echo ""
echo "== Step 4: Choose ZIM files to download =="
echo "You can pick multiple options (e.g., 1 3 4)."
echo ""
echo "1) Wikipedia (no images, English)"
echo "2) Wikipedia (with images, English)"
echo "3) Wikibooks (English)"
echo "4) Gutenberg (Books)"
echo "5) Custom URLs"

read -p "Enter your choices [e.g. 1 3]: " CHOICES

mkdir -p /var/kiwix
cd /var/kiwix

ZIM_URLS=()

for choice in $CHOICES; do
  case $choice in
    1)
      ZIM_URLS+=("https://download.kiwix.org/zim/wikipedia/wikipedia_en_all_nopic.zim")
      ;;
    2)
      ZIM_URLS+=("https://download.kiwix.org/zim/wikipedia/wikipedia_en_all_maxi.zim")
      ;;
    3)
      ZIM_URLS+=("https://download.kiwix.org/zim/wikibooks/wikibooks_en_all.zim")
      ;;
    4)
      ZIM_URLS+=("https://download.kiwix.org/zim/gutenberg/gutenberg_en_all.zim")
      ;;
    5)
      read -p "Enter custom ZIM URLs (space-separated): " CUSTOM_URLS
      for url in $CUSTOM_URLS; do
        ZIM_URLS+=("$url")
      done
      ;;
    *)
      echo "⚠ Skipping invalid choice: $choice"
      ;;
  esac
done

echo "== Downloading selected ZIM files =="
for url in "${ZIM_URLS[@]}"; do
  echo "📥 Downloading $url ..."
  wget -c "$url"
done

# Step 6: Create systemd service
echo "== Creating systemd service =="

chown -R www-data:www-data /var/kiwix
chmod -R 755 /var/kiwix

cat <<EOT > /etc/systemd/system/kiwix-serve.service
[Unit]
Description=Kiwix Server
After=network.target

[Service]
ExecStart=/usr/local/bin/kiwix-serve --port=$KIWI_PORT --address=$KIWI_IP /var/kiwix/*.zim
Restart=always
User=www-data
WorkingDirectory=/var/kiwix

[Install]
WantedBy=multi-user.target
EOT

# Step 7: Enable & start service
echo "== Enabling and starting Kiwix service =="
systemctl daemon-reload
systemctl enable kiwix-serve
systemctl restart kiwix-serve

echo ""
echo "✅ Kiwix server setup complete!"
echo "➡ Access it at: http://$KIWI_IP:$KIWI_PORT"
echo "📚 All ZIM files in /var/kiwix will be served automatically."
