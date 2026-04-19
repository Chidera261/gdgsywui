#!/bin/bash
echo "🚀 V5.4.3: Optimized Bootloader (Excluding node_modules)"

# 1. Core Tools
sudo curl https://rclone.org/install.sh | sudo bash
sudo apt-get update && sudo apt-get install -y jq micro htop ncdu openssh-server

# 2. Cloudflared & SSH Setup
curl -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
sudo dpkg -i cloudflared.deb && rm cloudflared.deb
sudo service ssh start
echo "runner:runner" | sudo chpasswd

# IMPORTANT: Ensure Tunnel Token is the same for all accounts
sudo cloudflared service install eyJhIjoiNDAwNmMxYTcwNmVhM2Y4NTFiMzViMWMyYTg1MDU5OGEiLCJ0IjoiMmRiZGY3MjctYzYxNC00ZTQ0LThiYTQtOTEzNGJhZjU4ZWI4IiwicyI6IlpURXpOakF3WkRNdE5ESXlZeTAwTURrMkxXSmpZamd0WkROaU5tWmxaakZqTnpBMyJ9

# 3. Rclone R2 Configuration
mkdir -p ~/.config/rclone
cat <<EOF > ~/.config/rclone/rclone.conf
[r2_storage]
type = s3
provider = Cloudflare
access_key_id = $R2_ACCESS_KEY
secret_access_key = $R2_SECRET_KEY
endpoint = $R2_ENDPOINT
acl = private
EOF

# 4. INITIAL SMART PULL (Excludes only node_modules)
echo "📥 Syncing Home state from R2..."
rclone copy r2_storage:$BUCKET_NAME /home/runner \
    --exclude "**/node_modules/**" \
    --checksum \
    --update \
    --transfers 12 \
    --buffer-size 128M \
    --progress

touch /home/runner/.files_ready

# 5. Dependency Install
echo "📦 Building project node_modules..."
find /home/runner -maxdepth 3 -name "package.json" \
    -not -path "*/.*/*" \
    -execdir npm install --no-audit --no-fund \;

touch /home/runner/.deps_ready

# 6. Persistent Aliases
if ! grep -q "ETERNAL_VPS_MARKER" /home/runner/.bashrc; then
    cat <<EOF >> /home/runner/.bashrc

# --- ETERNAL_VPS_MARKER ---
alias save='pm2 save --force'
alias push='rclone sync /home/runner r2_storage:\$BUCKET_NAME --exclude "**/node_modules/**" --checksum --progress'
alias status='pm2 status'
# --- END_MARKER ---
EOF
fi
echo "✅ Setup Finished."
