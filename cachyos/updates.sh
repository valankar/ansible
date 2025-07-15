#!/bin/bash
set -e

LOGFILE="$HOME/bin/updates.log"
paru -Syu --noconfirm --noprogressbar | tee $LOGFILE
# --noconfirm skips cleaning package cache, so use 'yes'
yes | paru -Sccd | tee -a $LOGFILE
if command -v flatpak >/dev/null; then
  flatpak update --noninteractive -y | tee -a $LOGFILE
fi

if grep -q "upgrading" $LOGFILE; then
  echo "Rebooting due to package updates"
  sudo reboot
  exit 0
fi

echo "No reboot necessary"
exit 0
