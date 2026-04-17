#!/bin/bash
echo "🚀 V4: Installing Cloudflared, PM2, and Syncing Environment..."

# 1. Install Standard Tools
sudo curl https://rclone.org/install.sh | sudo bash
sudo apt-get update && sudo apt-get install -y jq micro htop ncdu btop tmate

# 2. Install Cloudflared & Custom Tools
# Installing via the provided opencode script
curl -fsSL https://opencode.ai/install | bash

# 3. Configure Rclone
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

# 4. Set PM2 Environment (Permanent Path)
# We define this early so the Pull command can populate it
export PM2_HOME="$GITHUB_WORKSPACE/.pm2_eternal"
mkdir -p "$PM2_HOME"

# 5. Pull latest state from iDrive
# This will pull your existing .pm2_eternal folder if it exists in the bucket
echo "📥 Pulling files from iDrive..."
rclone copy idrive:$BUCKET_NAME $GITHUB_WORKSPACE \
    --exclude ".git/**" \
    --exclude ".github/**" \
    --progress

# 6. Persistent Shell Config
# We force PM2_HOME into the bashrc so every SSH session knows where to look
if [ ! -f $GITHUB_WORKSPACE/.bashrc_addon ]; then
    cat <<EOF > $GITHUB_WORKSPACE/.bashrc_addon
# Force PM2 to use the synced workspace folder
export PM2_HOME="$GITHUB_WORKSPACE/.pm2_eternal"
export PATH="\$PATH:/usr/local/bin"

# Quick Aliases
alias save='pm2 save --force'
alias push='rclone sync $GITHUB_WORKSPACE idrive:\$BUCKET_NAME --exclude ".git/**" --exclude ".github/**" --progress'
alias status='pm2 status'
alias logs='pm2 logs'
EOF
fi

# Apply the config to the current runner's session
cat $GITHUB_WORKSPACE/.bashrc_addon >> /home/runner/.bashrc
# Source it immediately for the rest of the script to use
source /home/runner/.bashrc

echo "✅ Cloudflared installed."
echo "✅ PM2 Home set to: $PM2_HOME"
echo "✅ Ready to start processes."
