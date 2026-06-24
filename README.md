Ansible config for new machines.

# Setup

```shell
ansible-galaxy collection install hifis.toolkit
```

# Upgrade
```shell
uv lock --upgrade
uv sync
ansible-galaxy collection install -U hifis.toolkit
```

# Run

```shell
ansible-playbook -i inventory.ini debian.yaml --ask-become-pass

# Limiting to a host
ansible-playbook -i inventory.ini cachyos.yaml --ask-become-pass --limit 192.168.0.3

# Dry Run
ansible-playbook -i inventory.ini cachyos.yaml --ask-become-pass --check --diff --limit localhost
```

# alpine incus host

## Installation

```shell
export ROOTFS=btrfs
setup-alpine
```

Update `/etc/apk/repositories` with latest version.

## Packages

```
```
```shell
doas apk -U upgrade
doas apk add incus incus-client fuse3
doas rc-update add incusd
doas rc-update add fuse
reboot
```

## Incus

```shell
doas incus admin init
doas addgroup valankar incus
```

## Ansible

```shell
# Master
incus launch images:archlinux ansible
incus exec ansible -- pacman -Syu ansible ansible-core git openssh
incus exec ansible -- ansible-galaxy collection install kewlfft.aur

# Target
incus launch images:archlinux arch
incus exec arch -- pacman -Syu python openssh
incus exec arch -- systemctl enable sshd
incus exec arch -- passwd root
incus exec arch -- vi /etc/ssh/sshd_config
# Add PermitRootLogin yes to /etc/ssh/sshd_config
incus exec arch -- systemctl start sshd

# Master
incus exec ansible -- bash
# SSH to target IP as root to update known_hosts
git clone https://github.com/valankar/ansible.git
# Update inventory.ini with IP
ansible-playbook -i inventory.ini archlinux.yaml -k
```
