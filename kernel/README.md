This is a compiled kernel with BBRv3 as Debian packages.

It was compiled from the [BBR kernel tree](https://github.com/google/bbr/tree/v3) per the [Debian handbook](https://debian-handbook.info/browse/stable/sect.kernel-compilation.html). It does *not* contain any distribution patches (e.g from Debian).

The kernel config used is based on the [cloud config](https://packages.debian.org/bookworm/amd64/linux-config-6.1/filelist) of Debian 12 (Bookworm). It has been changed to make `bbr` the default congestion control.

Install with:

```shell
sudo dpkg -i linux-*
```

Tested on Debian 12 and Ubuntu Server v24.04.2 LTS in a Proxmox VM.