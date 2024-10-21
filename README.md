# Ansible User Setup Project

This project contains scripts to automatically set up an Ansible user on multiple Linux hosts.

## Files

- `setup-ansible-user.sh`: Bash script to create the ansible user and set up SSH access.
- `deploy-and-execute.sh`: Script to deploy and execute the setup script on remote hosts.
- `inventory`: Ansible inventory file containing host information.

## Usage

### 1. Running directly on the target host

To run the setup script directly on a target host:

```bash
sudo ./setup-ansible-user.sh [--debug] [--log]
```

Options:
- `--debug`: Enables debug mode, showing all output.
- `--log`: Creates a log file named `setup-ansible-user-DATE.log`.

### 2. Running from an Ansible bastion host

To deploy and execute the setup script on multiple remote hosts:

```bash
./deploy-and-execute.sh [--debug] [--log]
```

This script will:
- Copy the `setup-ansible-user.sh` script to each host in the inventory.
- Execute the setup script on each remote host.
- Optionally show debug output or create log files.

## Notes

- Always test the scripts on non-production systems before running them on critical infrastructure.
- Ensure that you have SSH access to the target hosts before running the deployment script.
- The scripts handle different OS families (Debian/Ubuntu and Red Hat) automatically.
