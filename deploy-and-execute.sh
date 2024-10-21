#!/bin/bash

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
            LOG_FILE="deploy-and-execute-$(date +%Y%m%d-%H%M%S).log"
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
	set -x
    fi
    if [ "$LOG" = true ]; then
        echo "$message" >> "$LOG_FILE"
    fi
}

# Function to run command with optional debug output
run_command() {
    if [ "$DEBUG" = true ]; then
        "$@"
    else
        "$@" >/dev/null 2>&1
    fi
}

# Read inventory file and extract hosts
HOSTS=$(grep ansible_host inventory | awk '{print $2}' | cut -d'=' -f2)

# Current user
CURRENT_USER=$(whoami)

# Loop through each host
for HOST in $HOSTS; do
    log_message "Processing host: $HOST"

    # Copy the setup script to the remote host
    log_message "Copying setup-ansible-user.sh to $HOST"
    run_command scp setup-ansible-user.sh ${CURRENT_USER}@${HOST}:/tmp/

    # Execute the setup script on the remote host
    log_message "Executing setup-ansible-user.sh on $HOST"
    REMOTE_CMD="sudo /tmp/setup-ansible-user.sh"
    if [ "$DEBUG" = true ]; then
        REMOTE_CMD="$REMOTE_CMD --debug"
    fi
    if [ "$LOG" = true ]; then
        REMOTE_CMD="$REMOTE_CMD --log"
    fi
    run_command ssh ${CURRENT_USER}@${HOST} "$REMOTE_CMD"

    # Clean up
    log_message "Cleaning up temporary files on $HOST"
    run_command ssh ${CURRENT_USER}@${HOST} "rm /tmp/setup-ansible-user.sh"

    log_message "Finished processing host: $HOST"
done

log_message "Deployment and execution completed for all hosts"

set +x
