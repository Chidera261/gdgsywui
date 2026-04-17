#!/bin/bash
echo "🛠️ V4: Mounting Eternal Home via iDrive e2..."

# 1. Install Rclone & System Tools
sudo curl https://rclone.org/install.sh | sudo bash
sudo apt-get update && sudo apt-get install -y fuse3 jq micro htop ncdu btop

# 2. Configure rclone for iDrive e2
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

# 3. Prepare Mount Point
mkdir -p ~/home

# 4. Mount iDrive
rclone mount idrive:$BUCKET_NAME ~/home \
    --vfs-cache-mode writes \
    --vfs-cache-max-size 10G \
    --daemon

echo "⏳ Waiting for cloud mount to stabilize..."
for i in {1..15}; do
    if mountpoint -q ~/home; then
        echo "✅ Mount detected!"
        break
    fi
    sleep 1
done

# 5. Link PM2 state to the cloud drive
mkdir -p ~/home/.pm2
rm -rf ~/.pm2
ln -sf ~/home/.pm2 ~/.pm2

# 6. Persistent Shell Config
if [ ! -f ~/home/.bashrc_addon ]; then
    cat <<EOF > ~/home/.bashrc_addon
export PM2_HOME=~/.pm2
alias save='npx pm2 save --force'
alias status='npx pm2 status'
alias logs='npx pm2 logs'
EOF
fi

# Append cloud config to local session
cat ~/home/.bashrc_addon >> ~/.bashrc

# 7. Auto-install apps
if [ -f ~/home/apps.txt ]; then
    echo "📦 Re-installing custom apps..."
    APPS=$(cat ~/home/apps.txt)
    sudo apt-get install -y $APPS
fi

echo "✅ Environment Ready."
