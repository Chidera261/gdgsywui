#!/bin/bash
echo "🚀 V5: Eternal Cloudflare Tunnel Edition"

# 1. Install Standard Tools
sudo curl https://rclone.org/install.sh | sudo bash
sudo apt-get update && sudo apt-get install -y jq micro htop ncdu btop tmate openssh-server

# 2. Install Cloudflared (Official)
curl -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
sudo dpkg -i cloudflared.deb
rm cloudflared.deb

# 3. Setup SSH & User Security
sudo service ssh start
# Sets the 'runner' password to 'runner' - change this if you want more security
echo "runner:runner" | sudo chpasswd

# 4. Install Cloudflare Tunnel as a System Service
# Using your provided token
sudo cloudflared service install eyJhIjoiNDAwNmMxYTcwNmVhM2Y4NTFiMzViMWMyYTg1MDU5OGEiLCJ0IjoiMmRiZGY3MjctYzYxNC00ZTQ0LThiYTQtOTEzNGJhZjU4ZWI4IiwicyI6IlpURXpOakF3WkRNdE5ESXlZeTAwTURrMkxXSmpZamd0WkROaU5tWmxaakZqTnpBMyJ9

# 5. Rclone & PM2 Setup (V4 logic)
mkdir -p ~/.config/rclone
cat <<EOF > ~/.config/rclone/rclone.conf
[idrive]
type = s3
provider = Other
access_key_id = $IDRIVE_ACCESS_KEY
secret_access_key = $IDRIVE_SECRET_KEY
endpoint = $IDRIVE_ENDPOINT
region = us-west-2
EOF

export PM2_HOME="$GITHUB_WORKSPACE/.pm2_eternal"
mkdir -p "$PM2_HOME"

# 6. Pull Environment
echo "📥 Syncing from iDrive..."
rclone copy idrive:$BUCKET_NAME $GITHUB_WORKSPACE \
    --exclude ".git/**" \
    --exclude ".github/**" \
    --exclude "**/node_modules/**" \
    --progress

# 7. Blocking Dependencies
if [ -f "$GITHUB_WORKSPACE/invest/package.json" ]; then
    echo "📦 Installing 'invest' dependencies..."
    cd "$GITHUB_WORKSPACE/invest" && npm install --no-audit --no-fund && cd "$GITHUB_WORKSPACE"
fi

touch .deps_ready

# 8. Persistent Shell Config
if [ ! -f $GITHUB_WORKSPACE/.bashrc_addon ]; then
    cat <<EOF > $GITHUB_WORKSPACE/.bashrc_addon
export PM2_HOME="$GITHUB_WORKSPACE/.pm2_eternal"
alias save='pm2 save --force'
alias push='rclone sync \$GITHUB_WORKSPACE idrive:\$BUCKET_NAME --exclude \".git/**\" --exclude \".github/**\" --exclude \"**/node_modules/**\" --progress'
EOF
fi

cat $GITHUB_WORKSPACE/.bashrc_addon >> /home/runner/.bashrc
echo "✅ V5 Ready. Cloudflare Tunnel Active."
