#!/bin/bash
echo "🚀 V4: Initializing SSD + Cloud Sync (Stability Optimized)..."

# 1. Install Tools
sudo curl https://rclone.org/install.sh | sudo bash
sudo apt-get update && sudo apt-get install -y jq micro htop ncdu btop tmate

# 2. Install Cloudflared (Official)
curl -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
sudo dpkg -i cloudflared.deb
rm cloudflared.deb

# 3. Install Opencode
curl -fsSL https://opencode.ai/install | bash

# 4. Configure Rclone
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

# 5. Set PM2 Environment
export PM2_HOME="$GITHUB_WORKSPACE/.pm2_eternal"
mkdir -p "$PM2_HOME"

# 6. Pull from iDrive
echo "📥 Syncing from iDrive..."
rclone copy idrive:$BUCKET_NAME $GITHUB_WORKSPACE \
    --exclude ".git/**" \
    --exclude ".github/**" \
    --exclude "**/node_modules/**" \
    --progress

# 7. BLOCKING: Install Dependencies
# This ensures apps don't start with missing modules
if [ -f "$GITHUB_WORKSPACE/invest/package.json" ]; then
    echo "📦 Installing 'invest' dependencies (this may take a moment)..."
    cd "$GITHUB_WORKSPACE/invest" && npm install --no-audit --no-fund && cd "$GITHUB_WORKSPACE"
fi

# Signal to the workflow that we are ready
touch .deps_ready

# 8. Persistent Shell Config
if [ ! -f $GITHUB_WORKSPACE/.bashrc_addon ]; then
    cat <<EOF > $GITHUB_WORKSPACE/.bashrc_addon
export PM2_HOME="$GITHUB_WORKSPACE/.pm2_eternal"
export PATH="\$PATH:/usr/local/bin"
alias save='pm2 save --force'
alias status='pm2 status'
alias logs='pm2 logs'
alias push='rclone sync $GITHUB_WORKSPACE idrive:\$BUCKET_NAME --exclude \".git/**\" --exclude \".github/**\" --exclude \"**/node_modules/**\" --progress'
EOF
fi

cat $GITHUB_WORKSPACE/.bashrc_addon >> /home/runner/.bashrc
echo "✅ Environment Ready & Dependencies Installed."
