#!/bin/bash

# Check if the script is run with sudo
if [ "$EUID" -ne 0 ]; then
    echo "Error: This script must be run with sudo privileges."
    echo "Please run the script as: sudo $0"
    exit 1
fi

# Set the username
USERNAME="ansible_user"

# Create the user if it doesn't exist
if ! id "$USERNAME" &>/dev/null; then
    useradd -m -s /bin/bash $USERNAME
    echo "${USERNAME}:password123" | chpasswd
fi

# Determine the OS and set appropriate sudo permissions
if [ -f /etc/debian_version ]; then
    # Debian/Ubuntu
    SUDO_COMMANDS="/usr/bin/apt-get update, /usr/bin/apt-get upgrade, /usr/bin/apt-get dist-upgrade, /usr/bin/apt-get autoremove, /usr/bin/apt-get clean, /sbin/reboot"
    OS_NAME="Debian/Ubuntu"
elif [ -f /etc/redhat-release ]; then
    # Red Hat/CentOS
    SUDO_COMMANDS="/usr/bin/dnf update, /usr/bin/dnf upgrade, /usr/bin/dnf autoremove, /sbin/reboot"
    OS_NAME="Red Hat/CentOS"
else
    echo "Unsupported operating system"
    exit 1
fi

# Add user to sudoers with specific permissions
echo "$USERNAME ALL=(ALL) NOPASSWD: $SUDO_COMMANDS" | tee /etc/sudoers.d/$USERNAME

# Set up SSH key authentication
SSH_DIR="/home/$USERNAME/.ssh"
mkdir -p "$SSH_DIR"

# Check if id_rsa.pub already exists and create a unique filename if it does
KEY_FILE="$SSH_DIR/id_rsa"
KEY_SUFFIX=1
while [ -f "${KEY_FILE}.pub" ]; do
    KEY_FILE="$SSH_DIR/id_rsa_${KEY_SUFFIX}"
    ((KEY_SUFFIX++))
done

# Generate the SSH key
su - $USERNAME -c "ssh-keygen -t rsa -b 4096 -f '$KEY_FILE' -N ''"

# Add the new key to authorized_keys
su - $USERNAME -c "cat '${KEY_FILE}.pub' >> '$SSH_DIR/authorized_keys'"

# Set correct permissions
chown -R $USERNAME:$USERNAME "$SSH_DIR"
chmod 700 "$SSH_DIR"
chmod 600 "$SSH_DIR/authorized_keys"

# Update SSH config file
CONFIG_FILE="$SSH_DIR/config"
su - $USERNAME -c "touch '$CONFIG_FILE'"
su - $USERNAME -c "echo 'Host *
    IdentityFile $KEY_FILE' >> '$CONFIG_FILE'"

chmod 600 "$CONFIG_FILE"

echo "User $USERNAME created with limited sudo permissions for $OS_NAME and SSH key generated."
echo "SSH key created: $KEY_FILE"

# Function to copy key to local machine
copy_to_local() {
    # Get the IP address of the user's machine
    read -p "Enter the IP address of your local machine: " LOCAL_IP
    
    # Get the username on the local machine
    read -p "Enter your username on the local machine: " LOCAL_USER
    
    # Copy the public key to the local machine
    su - $USERNAME -c "ssh-copy-id -i '${KEY_FILE}.pub' ${LOCAL_USER}@${LOCAL_IP}"
    
    if [ $? -eq 0 ]; then
        echo "Public key successfully copied to your local machine."
    else
        echo "Failed to copy public key. You may need to manually copy it."
        echo "Here's the public key:"
        cat "${KEY_FILE}.pub"
    fi
}

# Function to copy key to the host running the script
copy_to_current_host() {
    if [ -n "$SSH_CLIENT" ]; then
        CLIENT_IP=$(echo $SSH_CLIENT | awk '{print $1}')
        echo "Detected SSH client IP: $CLIENT_IP"
        read -p "Is this the correct IP to copy the key to? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            read -p "Enter your username on $CLIENT_IP: " CLIENT_USER
            su - $USERNAME -c "ssh-copy-id -i '${KEY_FILE}.pub' ${CLIENT_USER}@${CLIENT_IP}"
            if [ $? -eq 0 ]; then
                echo "Public key successfully copied to $CLIENT_IP."
            else
                echo "Failed to copy public key. You may need to manually copy it."
                echo "Here's the public key:"
                cat "${KEY_FILE}.pub"
            fi
        else
            copy_to_local
        fi
    else
        echo "Not connected via SSH. Falling back to manual input."
        copy_to_local
    fi
}

# Ask user where they want to copy the public key
echo "Where would you like to copy the public key?"
echo "1. To the host you're running this script from"
echo "2. To a different local machine"
echo "3. Don't copy, just show me the key"
read -p "Enter your choice (1/2/3): " -n 1 -r
echo

case $REPLY in
    1)  copy_to_current_host
        ;;
    2)  copy_to_local
        ;;
    3)  echo "Here's the public key for manual copying:"
        cat "${KEY_FILE}.pub"
        ;;
    *)  echo "Invalid option. Here's the public key for manual copying:"
        cat "${KEY_FILE}.pub"
        ;;
esac
