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

# 3. Prepare the Mount Point
mkdir -p ~/home

# 4. Mount iDrive (Background)
# --vfs-cache-mode writes allows PM2 to write its database/logs directly to the cloud
rclone mount idrive:$BUCKET_NAME ~/home \
    --vfs-cache-mode writes \
    --vfs-cache-max-size 10G \
    --daemon

# Wait for mount to stabilize
sleep 5

# 5. Reconstruct System Environment
# Create core folders on iDrive if it's the very first run
mkdir -p ~/home/.pm2
mkdir -p ~/home/bin
mkdir -p ~/home/projects

# Link PM2 state to the cloud
rm -rf ~/.pm2
ln -sf ~/home/.pm2 ~/.pm2

# 6. Persistent Shell Config
# We append a custom addon file from iDrive to the local .bashrc
if [ -f ~/home/.bashrc_addon ]; then
    cat ~/home/.bashrc_addon >> ~/.bashrc
else
    echo "export PM2_HOME=~/.pm2" > ~/home/.bashrc_addon
    echo "alias save='pm2 save --force'" >> ~/home/.bashrc_addon
    echo "alias status='pm2 status'" >> ~/home/.bashrc_addon
fi

# 7. Auto-install stored programs list
if [ -f ~/home/apps.txt ]; then
    sudo apt-get install -y \$(cat ~/home/apps.txt)
fi

echo "✅ Eternal Home is live at ~/home"
