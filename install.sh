#!/bin/bash
echo "🚀 V4: Installing Cloudflared, Opencode, and Syncing Environment..."

# 1. Install Standard Tools
sudo curl https://rclone.org/install.sh | sudo bash
sudo apt-get update && sudo apt-get install -y jq micro htop ncdu btop tmate

# 2. Install Cloudflared (Official Binary)
echo "☁️ Installing Cloudflared..."
curl -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
sudo dpkg -i cloudflared.deb
rm cloudflared.deb

# 3. Install Custom Opencode Tool
echo "🛠️ Installing Opencode..."
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

# 6. Pull latest state from iDrive
echo "📥 Pulling files from iDrive..."
rclone copy idrive:$BUCKET_NAME $GITHUB_WORKSPACE \
    --exclude ".git/**" \
    --exclude ".github/**" \
    --progress

# 7. Persistent Shell Config
if [ ! -f $GITHUB_WORKSPACE/.bashrc_addon ]; then
    cat <<EOF > $GITHUB_WORKSPACE/.bashrc_addon
# Force PM2 to use the synced workspace folder
export PM2_HOME="$GITHUB_WORKSPACE/.pm2_eternal"
export PATH="\$PATH:/usr/local/bin"

# Aliases
alias save='pm2 save --force'
alias push='rclone sync $GITHUB_WORKSPACE idrive:\$BUCKET_NAME --exclude ".git/**" --exclude ".github/**" --progress'
alias status='pm2 status'
alias logs='pm2 logs'
EOF
fi

# Apply to current session
cat $GITHUB_WORKSPACE/.bashrc_addon >> /home/runner/.bashrc
source /home/runner/.bashrc

echo "✅ Cloudflared, Opencode, and PM2 are now ready."
