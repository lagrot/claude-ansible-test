# Linux Host Update Project

This project contains scripts and playbooks to automatically update and maintain multiple Linux hosts.

## Setup

1. Run the `setup-user-ssh.sh` script on each target host to create the `ansible_user` and set up SSH access.
2. Copy the generated public key to your local machine and update the `ansible_ssh_private_key_file` path in the inventory file.

## Usage

1. Update the `inventory` file with your host information.
2. Run the Ansible playbook:

```
ansible-playbook -i inventory update-hosts-playbook.yml
```

This will update all hosts, reboot them, and clean old files.

## Files

- `setup-user-ssh.sh`: Bash script to create the ansible user and set up SSH access.
- `update-hosts-playbook.yml`: Ansible playbook to update, reboot, and clean Linux hosts.
- `inventory`: Ansible inventory file containing host information.

## Notes

- The playbook handles different OS families (Debian/Ubuntu and Red Hat) automatically.
- Make sure to replace the default password in the setup script with a secure one.
- Always test the playbook on non-production systems before running it on critical infrastructure.
