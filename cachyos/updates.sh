#!/bin/bash
set -e

if systemctl list-unit-files kopia.service >/dev/null; then
  echo "Running kopia"
  sudo systemctl start kopia
fi

LOGFILE="$HOME/bin/updates.log"
paru -Syu --noconfirm --noprogressbar | tee $LOGFILE
# --noconfirm skips cleaning package cache, so use 'yes'
yes | paru -Sccd | tee -a $LOGFILE
if command -v flatpak >/dev/null; then
  flatpak update --noninteractive -y | tee -a $LOGFILE
fi

if grep -q "upgrading" $LOGFILE; then
  echo "Rebooting due to package updates"
  if [ "$XDG_CURRENT_DESKTOP" = "KDE" ]; then
    qdbus6 org.kde.Shutdown /Shutdown org.kde.Shutdown.logoutAndReboot
  else
    sudo reboot
  fi
  exit 0
fi

echo "No reboot necessary"
exit 0
