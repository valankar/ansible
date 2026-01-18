#!/bin/bash
set -e

if systemctl list-unit-files kopia.service >/dev/null; then
  echo "Running kopia"
  sudo systemctl start kopia
fi

LOGFILE="$HOME/bin/updates.log"
paru -Syu --noconfirm --noprogressbar 2>&1 | tee $LOGFILE
# --noconfirm skips cleaning package cache, so use 'yes'
yes | paru -Sccd 2>&1 | tee -a $LOGFILE
# https://gitlab.archlinux.org/pacman/pacman/-/issues/297
sudo find /var/cache/pacman/pkg/ -mindepth 1 -type d -empty -delete
if command -v flatpak >/dev/null; then
  sudo flatpak update --noninteractive -y 2>&1 | tee -a $LOGFILE
fi

if grep -q "upgrading" $LOGFILE; then
  echo "Rebooting due to package updates"
  if pgrep plasmashell >/dev/null; then
    export DISPLAY=:0
    export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus
    if qdbus6 org.kde.Shutdown /Shutdown org.kde.Shutdown.logoutAndReboot; then
      exit 0
    fi
  fi
  sudo reboot
  exit 0
fi

echo "No reboot necessary"
exit 0
