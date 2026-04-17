#!/bin/bash
echo "🚀 V4: Initializing Local SSD with iDrive Cloud Sync..."

# 1. Install Rclone & System Tools
sudo curl https://rclone.org/install.sh | sudo bash
sudo apt-get update && sudo apt-get install -y jq micro htop ncdu btop tmate

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

# 3. Pull latest state from Cloud to the Current Folder
echo "📥 Syncing state from iDrive to $PWD..."
# This pulls files from iDrive into your current repo folder
rclone copy idrive:$BUCKET_NAME $GITHUB_WORKSPACE --progress

# 4. Link PM2 state
# We keep the daemon local (fast) but the dump file in our tracked folder
mkdir -p /home/runner/.pm2
[ -f $GITHUB_WORKSPACE/.pm2_dump ] && cp $GITHUB_WORKSPACE/.pm2_dump /home/runner/.pm2/dump.pm2

# 5. Persistent Shell Config
if [ ! -f $GITHUB_WORKSPACE/.bashrc_addon ]; then
    cat <<EOF > $GITHUB_WORKSPACE/.bashrc_addon
export PM2_HOME=/home/runner/.pm2
alias save='pm2 save --force && cp /home/runner/.pm2/dump.pm2 $GITHUB_WORKSPACE/.pm2_dump'
alias status='pm2 status'
alias logs='pm2 logs'
alias push='rclone sync $GITHUB_WORKSPACE idrive:\$BUCKET_NAME --progress'
EOF
fi

# Apply the cloud configuration
cat $GITHUB_WORKSPACE/.bashrc_addon >> /home/runner/.bashrc

# 6. Auto-install stored programs list
if [ -f $GITHUB_WORKSPACE/apps.txt ]; then
    echo "📦 Re-installing custom apps..."
    sudo apt-get install -y $(cat $GITHUB_WORKSPACE/apps.txt)
fi

echo "✅ Environment Ready in $GITHUB_WORKSPACE"
