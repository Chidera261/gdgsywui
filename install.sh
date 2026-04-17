#!/bin/bash
echo "🚀 V4: Fixing PM2 Path & Syncing..."

# 1. Install Tools
sudo curl https://rclone.org/install.sh | sudo bash
sudo apt-get update && sudo apt-get install -y jq micro htop ncdu btop tmate

# 2. Configure Rclone
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

# 3. SET PM2 PERMANENT HOME (Inside Workspace)
# This makes PM2 save EVERYTHING inside your synced folder
export PM2_HOME="$GITHUB_WORKSPACE/.pm2_eternal"
mkdir -p "$PM2_HOME"

# 4. Pull from iDrive
echo "📥 Syncing from iDrive..."
rclone copy idrive:$BUCKET_NAME $GITHUB_WORKSPACE \
    --exclude ".git/**" \
    --exclude ".github/**" \
    --progress

# 5. Persistent Shell Config
if [ ! -f $GITHUB_WORKSPACE/.bashrc_addon ]; then
    cat <<EOF > $GITHUB_WORKSPACE/.bashrc_addon
# Force PM2 to use the synced workspace folder
export PM2_HOME="$GITHUB_WORKSPACE/.pm2_eternal"
alias save='pm2 save --force'
alias push='rclone sync $GITHUB_WORKSPACE idrive:\$BUCKET_NAME --exclude ".git/**" --exclude ".github/**" --progress'
EOF
fi

cat $GITHUB_WORKSPACE/.bashrc_addon >> /home/runner/.bashrc
echo "✅ PM2 Home set to: $PM2_HOME"
