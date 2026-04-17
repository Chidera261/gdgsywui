#!/bin/bash
echo "🛠️ V4: Initializing Eternal Storage..."

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

# 4. Mount iDrive with optimized flags for PM2 database stability
rclone mount idrive:$BUCKET_NAME ~/home \
    --vfs-cache-mode writes \
    --vfs-cache-max-size 10G \
    --dir-cache-time 2s \
    --daemon-timeout 30s \
    --daemon

echo "⏳ Waiting for cloud mount to stabilize..."
for i in {1..20}; do
    if mountpoint -q ~/home; then
        echo "✅ Mount detected!"
        break
    fi
    sleep 1
done

# 5. Link PM2 state to the cloud drive (CRITICAL FIX)
# We wipe any local PM2 folder and force the link to the cloud
rm -rf /home/runner/.pm2
mkdir -p ~/home/.pm2
ln -s /home/runner/home/.pm2 /home/runner/.pm2

# 6. Persistent Shell Config
if [ ! -f ~/home/.bashrc_addon ]; then
    cat <<EOF > ~/home/.bashrc_addon
export PM2_HOME=/home/runner/.pm2
alias save='npx pm2 save --force'
alias status='npx pm2 status'
alias logs='npx pm2 logs'
alias vs='code-server --auth none --port 8080'
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
