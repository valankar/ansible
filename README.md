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

# Alpine Incus host

## Installation

```shell
export ROOTFS=btrfs
setup-alpine
```

Update `/etc/apk/repositories` with latest version.

Add IPv6 to /etc/network/interfaces.

```shell
iface eth0 inet6 static
   address 2a01:4f8:1c18:7158::1/64
   dns-nameservers 2a01:4ff:ff00::add:1 2a01:4ff:ff00::add:2
   gateway fe80::1
```

## Packages

```shell
doas apk -U upgrade
doas apk add incus incus-client fuse3 rclone
doas rc-update add incusd
doas rc-update add fuse
doas rc-update add netmount
reboot
```

## Incus

```shell
doas incus admin init
doas addgroup valankar incus
```

### Port forwarding

```shell
incus network forward create incusbr0 EXTERNAL_IPV4
incus network forward create incusbr0 EXTERNAL_IPV6
incus network forward port add incusbr0 EXTERNAL_IPV4 tcp 80,443 INTERNAL_IPV4
incus network forward port add incusbr0 EXTERNAL_IPV6 tcp 80,443 INTERNAL_IPV6
```

### Snapshots

Hourly snapshots to the default profile:

```shell
incus profile set default snapshots.schedule=@hourly
incus profile set default snapshots.expiry=12H
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

# Target
incus exec arch -- su -l valankar -c arch-update
```

## Alpine automatic updates

### /etc/periodic/daily/apk-upgrade

```shell
#!/bin/sh

OUT=$(mktemp)

apk -U upgrade > "$OUT" 2>&1

if grep -qE "Upgrading|Installing" "$OUT"; then
    rm "$OUT"
    reboot
fi

rm "$OUT"
```

## Rclone SSH mount

The mount should be on the alpine host and start before Incus. This lets docker in containers access the mount when they boot.

### /etc/fstab

```
hbd: /mnt/hbd rclone rw,_netdev,uid=1001000,gid=1001000,allow_other,args2env,vfs-cache-mode=full,vfs-cache-max-size=5G,vfs-fast-fingerprint,config=/home/valankar/.config/rclone/rclone.conf,cache-dir=/var/cache/rclone
```

### /etc/conf.d/incusd

Adding this will make sure the rclone mount happens before Incus is started.

```
rc_need="netmount"
```

### Add device to container

```shell
incus config device add arch hbd disk source=/mnt/hbd path=/mnt/hbd
```
