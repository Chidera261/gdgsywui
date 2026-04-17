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
# vfs-cache-mode writes is essential for PM2 database integrity
rclone mount idrive:$BUCKET_NAME ~/home \
    --vfs-cache-mode writes \
    --vfs-cache-max-size 10G \
    --daemon

# Wait for mount to stabilize
echo "⏳ Waiting for cloud mount..."
sleep 8

# 5. Reconstruct System Environment
mkdir -p ~/home/.pm2
mkdir -p ~/home/bin
mkdir -p ~/home/projects

# Link PM2 state to the cloud drive
rm -rf ~/.pm2
ln -sf ~/home/.pm2 ~/.pm2

# 6. Persistent Shell Config
# We create a clean bridge between the system bashrc and your cloud bashrc
if [ ! -f ~/home/.bashrc_addon ]; then
    echo "export PM2_HOME=~/.pm2" > ~/home/.bashrc_addon
    echo "alias save='pm2 save --force'" >> ~/home/.bashrc_addon
    echo "alias status='pm2 status'" >> ~/home/.bashrc_addon
fi

# Apply the cloud aliases to the current session
cat ~/home/.bashrc_addon >> ~/.bashrc

# 7. Auto-install stored programs list (The Fixed Syntax)
if [ -f ~/home/apps.txt ]; then
    echo "📦 Re-installing your custom apps..."
    APPS=$(cat ~/home/apps.txt)
    sudo apt-get install -y $APPS
fi

echo "✅ Eternal Home is live at ~/home"
