#!/bin/bash
echo "🚀 V4: Initializing Local Environment with Cloud Sync..."

# 1. Install Rclone & Tools
sudo curl https://rclone.org/install.sh | sudo bash
sudo apt-get update && sudo apt-get install -y jq micro htop ncdu btop tmate

# 2. Configure rclone
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

# 3. Initial Pull from Cloud
echo "📥 Pulling latest state from iDrive..."
mkdir -p /home/runner/home
# Copy everything from iDrive to the local ~/home folder
rclone copy idrive:$BUCKET_NAME /home/runner/home --progress

# 4. Link PM2 to Local home
rm -rf /home/runner/.pm2
mkdir -p /home/runner/home/.pm2
ln -s /home/runner/home/.pm2 /home/runner/.pm2

# 5. Persistent Shell Config
if [ ! -f /home/runner/home/.bashrc_addon ]; then
    cat <<EOF > /home/runner/home/.bashrc_addon
export PM2_HOME=/home/runner/.pm2
alias save='pm2 save --force'
alias status='pm2 status'
alias logs='pm2 logs'
alias push='rclone sync /home/runner/home idrive:\$BUCKET_NAME --progress'
cd /home/runner/home
EOF
fi

# Apply aliases
cat /home/runner/home/.bashrc_addon >> /home/runner/.bashrc

# 6. Auto-install apps
if [ -f /home/runner/home/apps.txt ]; then
    sudo apt-get install -y $(cat /home/runner/home/apps.txt)
fi

echo "✅ Environment ready. Working directory: ~/home"
