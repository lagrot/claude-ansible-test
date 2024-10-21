#!/bin/bash

# Check if the script is run with sudo
if [ "$EUID" -ne 0 ]; then
    echo "Error: This script must be run with sudo privileges."
    echo "Please run the script as: sudo $0"
    exit 1
fi

# Initialize debug and log flags
DEBUG=false
LOG=false
LOG_FILE=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --debug)
            DEBUG=true
            shift
            ;;
        --log)
            LOG=true
            LOG_FILE="setup-ansible-user-$(date +%Y%m%d-%H%M%S).log"
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Function to log messages
log_message() {
    local message="$1"
    if [ "$DEBUG" = true ]; then
        echo "$message"
    fi
    if [ "$LOG" = true ]; then
        echo "$message" >> "$LOG_FILE"
    fi
}

# Set the username
USERNAME="ansible_user"

log_message "Starting setup for user: $USERNAME"

# Create the user if it doesn't exist
if ! id "$USERNAME" &>/dev/null; then
    useradd -m -s /bin/bash $USERNAME
    echo "${USERNAME}:password123" | chpasswd
    log_message "User $USERNAME created"
else
    log_message "User $USERNAME already exists"
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
    log_message "Unsupported operating system"
    exit 1
fi

log_message "Detected OS: $OS_NAME"

# Add user to sudoers with specific permissions
echo "$USERNAME ALL=(ALL) NOPASSWD: $SUDO_COMMANDS" | tee /etc/sudoers.d/$USERNAME
log_message "Added $USERNAME to sudoers with limited permissions"

# Set up SSH key authentication
SSH_DIR="/home/$USERNAME/.ssh"
mkdir -p "$SSH_DIR"
log_message "Created SSH directory: $SSH_DIR"

# Check if id_rsa.pub already exists and create a unique filename if it does
KEY_FILE="$SSH_DIR/id_rsa"
KEY_SUFFIX=1
while [ -f "${KEY_FILE}.pub" ]; do
    KEY_FILE="$SSH_DIR/id_rsa_${KEY_SUFFIX}"
    ((KEY_SUFFIX++))
done

log_message "Using SSH key file: $KEY_FILE"

# Generate the SSH key
su - $USERNAME -c "ssh-keygen -t rsa -b 4096 -f '$KEY_FILE' -N ''"
log_message "Generated SSH key"

# Add the new key to authorized_keys
su - $USERNAME -c "cat '${KEY_FILE}.pub' >> '$SSH_DIR/authorized_keys'"
log_message "Added public key to authorized_keys"

# Set correct permissions
chown -R $USERNAME:$USERNAME "$SSH_DIR"
chmod 700 "$SSH_DIR"
chmod 600 "$SSH_DIR/authorized_keys"
log_message "Set correct permissions for SSH directory and files"

# Update SSH config file
CONFIG_FILE="$SSH_DIR/config"
su - $USERNAME -c "touch '$CONFIG_FILE'"
su - $USERNAME -c "echo 'Host *
    IdentityFile $KEY_FILE' >> '$CONFIG_FILE'"

chmod 600 "$CONFIG_FILE"
log_message "Updated SSH config file"

echo "User $USERNAME created with limited sudo permissions for $OS_NAME and SSH key generated."
echo "SSH key created: $KEY_FILE"

# ... (rest of the script remains the same)
