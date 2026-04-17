#!/bin/bash
echo "🚀 V4: Initializing Eternal Cloud Environment..."

# 1. Install Rclone & System Tools
sudo curl https://rclone.org/install.sh | sudo bash
sudo apt-get update && sudo apt-get install -y fuse3 jq micro htop ncdu btop tmate

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
mkdir -p /home/runner/home

# 4. Mount iDrive with VFS caching for database/log support
rclone mount idrive:$BUCKET_NAME /home/runner/home \
    --vfs-cache-mode writes \
    --vfs-cache-max-size 10G \
    --dir-cache-time 2s \
    --daemon-timeout 30s \
    --daemon

echo "⏳ Waiting for cloud mount to stabilize..."
for i in {1..20}; do
    if mountpoint -q /home/runner/home; then
        echo "✅ Mount detected!"
        break
    fi
    sleep 1
done

# 5. Link PM2 state to the cloud drive
# Wipe local PM2 folder and force the link to the cloud
rm -rf /home/runner/.pm2
mkdir -p /home/runner/home/.pm2
ln -s /home/runner/home/.pm2 /home/runner/.pm2

# 6. Persistent Shell Config
# This file lives on iDrive and is applied every boot
if [ ! -f /home/runner/home/.bashrc_addon ]; then
    cat <<EOF > /home/runner/home/.bashrc_addon
export PM2_HOME=/home/runner/.pm2
alias save='pm2 save --force'
alias status='pm2 status'
alias logs='pm2 logs'
alias vs='code-server --auth none --port 8080'
EOF
fi

# Apply the cloud configuration to the current session
cat /home/runner/home/.bashrc_addon >> /home/runner/.bashrc

# 7. Auto-install additional apps list
if [ -f /home/runner/home/apps.txt ]; then
    echo "📦 Re-installing custom apps..."
    APPS=$(cat /home/runner/home/apps.txt)
    sudo apt-get install -y $APPS
fi

echo "✅ Environment Ready at ~/home"
