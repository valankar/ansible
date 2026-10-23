Ansible config for new machines.

# Setup

```shell
ansible-galaxy collection install kewlfft.aur
```

# Run

```shell
ansible-playbook -i inventory.ini archlinux.yaml --ask-become-pass

# Limiting to a host
ansible-playbook -i inventory.ini archlinux.yaml --ask-become-pass --limit 192.168.0.3

# Dry Run
ansible-playbook -i inventory.ini archlinux.yaml --ask-become-pass --check --diff --limit localhost
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
   gateway fe80::1
```

Add DNS servers to /etc/resolv.conf.

Add `compress=zstd` to btrfs / mount.

Setup time synchronization and check that it works (firewall might block source udp port 123 incoming)

```shell
setup-ntp
ntpd -d -n -p pool.ntp.org -q
```

## Packages

```shell
echo "@testing https://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories
apk -U upgrade
apk add curl gpg gpg-agent incus incus-client fuse3 rclone util-linux qemu-guest-agent kopia@testing
rc-update add incusd
rc-update add fuse
rc-update add netmount
rc-update add qemu-guest-agent
reboot
```

## Automatic updates

See `alpine/etc/periodic/daily/02-apk-upgrade`

## Incus

```shell
incus admin init
addgroup valankar incus
```

### Port forwarding

```shell
TARGET=arch
EXTERNAL_V4=1.2.3.4
EXTERNAL_V6=[aaaa:bbbb]
INTERNAL_V4=1.2.3.4
INTERNAL_V6=[aaaa:bbbb]

incus config device override $TARGET eth0
incus config device set $TARGET eth0 ipv4.address=$INTERNAL_V4
incus network set incusbr0 ipv6.dhcp.stateful=true
incus config device set $TARGET eth0 ipv6.address=$INTERNAL_V6

incus config device add $TARGET http-proxy proxy listen=tcp:$EXTERNAL_V4:80 connect=tcp:$INTERNAL_V4:80 nat=true
incus config device add $TARGET https-tcp-proxy proxy listen=tcp:$EXTERNAL_V4:443 connect=tcp:$INTERNAL_V4:443 nat=true
incus config device add $TARGET https-udp-proxy proxy listen=udp:$EXTERNAL_V4:443 connect=udp:$INTERNAL_V4:443 nat=true
incus config device add $TARGET http-proxy-v6 proxy listen=tcp:$EXTERNAL_V6:80 connect=tcp:$INTERNAL_V6:80 nat=true
incus config device add $TARGET https-tcp-proxy-v6 proxy listen=tcp:$EXTERNAL_V6:443 connect=tcp:$INTERNAL_V6:443 nat=true
incus config device add $TARGET https-udp-proxy-v6 proxy listen=udp:$EXTERNAL_V6:443 connect=udp:$INTERNAL_V6:443 nat=true
```

### Snapshots

Hourly snapshots to the default profile:

```shell
incus profile set default snapshots.schedule=@hourly
incus profile set default snapshots.expiry=12H
```

### Backups

To run backups and save remotely, see `alpine/etc/periodic/daily/01-incus-export`.

## Ansible

### Arch container

```shell
# Master
incus launch images:archlinux ansible
incus exec ansible -- pacman -Syu ansible ansible-core git openssh
incus exec ansible -- ansible-galaxy collection install kewlfft.aur

# Target
TARGET=arch-test
incus launch images:archlinux $TARGET
incus exec $TARGET -- pacman -Syu python openssh
incus exec $TARGET -- systemctl enable sshd
incus exec $TARGET -- passwd root
incus exec $TARGET -- vi /etc/ssh/sshd_config
# Add PermitRootLogin yes to /etc/ssh/sshd_config
# Disable udev explained below
incus restart $TARGET

# Master
incus exec ansible -- bash
# SSH to target as root to update known_hosts
git clone https://github.com/valankar/ansible.git
# Update inventory.ini with target
ansible-playbook -i inventory.ini archlinux.yaml -k

# Target
incus exec $TARGET -- su -l valankar -c paru
```

### Debian container

```shell
```


### Disable udev

On TARGET, [disable udev](https://wiki.archlinux.org/title/Incus#Disabling_udev_in_unprivileged_containers) because it does not work in 
non-privileged containers.

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
