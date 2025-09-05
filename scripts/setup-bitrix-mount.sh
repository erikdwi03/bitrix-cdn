#!/bin/bash
# Script to setup SSHFS mount on Bitrix server (Server1)
# This script should be run ON THE BITRIX SERVER

set -e

# Configuration
CDN_SERVER_IP="${CDN_SERVER_IP:-192.168.1.20}"
CDN_SERVER_USER="${CDN_SERVER_USER:-cdn}"
CDN_RESIZE_PATH="${CDN_RESIZE_PATH:-/var/www/cdn/upload/resize_cache}"
LOCAL_MOUNT_PATH="/var/www/bitrix/upload/resize_cache"
SSH_KEY_PATH="/root/.ssh/cdn_mount"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== Bitrix Server SSHFS Setup for resize_cache ===${NC}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run as root${NC}"
    exit 1
fi

# Install dependencies
echo -e "${YELLOW}Installing sshfs...${NC}"
apt-get update && apt-get install -y sshfs fuse

# Generate SSH key if not exists
if [ ! -f "$SSH_KEY_PATH" ]; then
    echo -e "${YELLOW}Generating SSH key...${NC}"
    ssh-keygen -t rsa -b 4096 -f "$SSH_KEY_PATH" -N ""
    echo -e "${GREEN}SSH key generated at $SSH_KEY_PATH${NC}"
    echo -e "${YELLOW}Copy this public key to CDN server:${NC}"
    cat "${SSH_KEY_PATH}.pub"
    echo -e "${YELLOW}Add it to /home/${CDN_SERVER_USER}/.ssh/authorized_keys on CDN server${NC}"
    read -p "Press enter after adding the key to CDN server..."
fi

# Test SSH connection
echo -e "${YELLOW}Testing SSH connection to CDN server...${NC}"
if ssh -o ConnectTimeout=5 -o BatchMode=yes -o StrictHostKeyChecking=no \
    -i "$SSH_KEY_PATH" "${CDN_SERVER_USER}@${CDN_SERVER_IP}" "echo 'SSH OK'"; then
    echo -e "${GREEN}SSH connection successful${NC}"
else
    echo -e "${RED}Cannot connect to CDN server${NC}"
    exit 1
fi

# Create mount point
echo -e "${YELLOW}Creating mount point...${NC}"
mkdir -p "$LOCAL_MOUNT_PATH"

# Add to fstab for persistent mount
echo -e "${YELLOW}Adding to /etc/fstab...${NC}"
FSTAB_ENTRY="${CDN_SERVER_USER}@${CDN_SERVER_IP}:${CDN_RESIZE_PATH} ${LOCAL_MOUNT_PATH} fuse.sshfs defaults,allow_other,default_permissions,IdentityFile=${SSH_KEY_PATH},reconnect,ServerAliveInterval=15,ServerAliveCountMax=3 0 0"

if ! grep -q "$LOCAL_MOUNT_PATH" /etc/fstab; then
    echo "$FSTAB_ENTRY" >> /etc/fstab
    echo -e "${GREEN}Added to /etc/fstab${NC}"
else
    echo -e "${YELLOW}Entry already exists in /etc/fstab${NC}"
fi

# Mount
echo -e "${YELLOW}Mounting resize_cache from CDN server...${NC}"
if mountpoint -q "$LOCAL_MOUNT_PATH"; then
    echo -e "${YELLOW}Already mounted, unmounting first...${NC}"
    fusermount -u "$LOCAL_MOUNT_PATH"
fi

mount "$LOCAL_MOUNT_PATH"

# Verify mount
if mountpoint -q "$LOCAL_MOUNT_PATH"; then
    echo -e "${GREEN}✓ Successfully mounted resize_cache from CDN server${NC}"
    echo -e "${GREEN}✓ Bitrix will now write resize_cache directly to CDN server${NC}"
    
    # Test write permissions
    TEST_FILE="$LOCAL_MOUNT_PATH/.mount_test_$(date +%s)"
    if touch "$TEST_FILE" 2>/dev/null; then
        rm "$TEST_FILE"
        echo -e "${GREEN}✓ Write permissions OK${NC}"
    else
        echo -e "${RED}✗ Cannot write to mount point${NC}"
        exit 1
    fi
else
    echo -e "${RED}✗ Mount failed${NC}"
    exit 1
fi

# Create systemd service for auto-mount
echo -e "${YELLOW}Creating systemd service...${NC}"
cat > /etc/systemd/system/cdn-resize-mount.service <<EOF
[Unit]
Description=Mount CDN resize_cache via SSHFS
After=network-online.target
Wants=network-online.target

[Service]
Type=forking
ExecStartPre=/bin/mkdir -p ${LOCAL_MOUNT_PATH}
ExecStart=/usr/bin/sshfs ${CDN_SERVER_USER}@${CDN_SERVER_IP}:${CDN_RESIZE_PATH} ${LOCAL_MOUNT_PATH} -o allow_other,default_permissions,IdentityFile=${SSH_KEY_PATH},reconnect,ServerAliveInterval=15,ServerAliveCountMax=3
ExecStop=/bin/fusermount -u ${LOCAL_MOUNT_PATH}
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable cdn-resize-mount.service
echo -e "${GREEN}✓ Systemd service created and enabled${NC}"

echo -e "${GREEN}"
echo "========================================="
echo "✓ SETUP COMPLETE!"
echo "========================================="
echo -e "${NC}"
echo "Bitrix server now mounts resize_cache from CDN server at:"
echo "  ${LOCAL_MOUNT_PATH} → ${CDN_SERVER_USER}@${CDN_SERVER_IP}:${CDN_RESIZE_PATH}"
echo ""
echo "Bitrix will write all resize_cache files directly to CDN server!"
echo "CDN server will automatically create WebP versions."