#!/bin/bash
echo "🚀 V4: Initializing Local SSD (Excluding Git/Workflows)..."

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

# 3. Initial Pull (Excluding Git and Workflows)
echo "📥 Pulling latest state from iDrive..."
rclone copy idrive:$BUCKET_NAME $GITHUB_WORKSPACE \
    --exclude ".git/**" \
    --exclude ".github/**" \
    --progress

# 4. Link PM2
mkdir -p /home/runner/.pm2
[ -f $GITHUB_WORKSPACE/.pm2_dump ] && cp $GITHUB_WORKSPACE/.pm2_dump /home/runner/.pm2/dump.pm2

# 5. Persistent Shell Config
if [ ! -f $GITHUB_WORKSPACE/.bashrc_addon ]; then
    cat <<EOF > $GITHUB_WORKSPACE/.bashrc_addon
export PM2_HOME=/home/runner/.pm2
alias save='pm2 save --force && cp /home/runner/.pm2/dump.pm2 $GITHUB_WORKSPACE/.pm2_dump'
alias push='rclone sync $GITHUB_WORKSPACE idrive:\$BUCKET_NAME --exclude ".git/**" --exclude ".github/**" --progress'
alias status='pm2 status'
EOF
fi

cat $GITHUB_WORKSPACE/.bashrc_addon >> /home/runner/.bashrc
echo "✅ Environment Ready."
