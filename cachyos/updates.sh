#!/bin/bash
set -e

LOGFILE="$HOME/bin/updates.log"
paru -Syu --noconfirm --noprogressbar | tee $LOGFILE
paru -Sc --noconfirm | tee -a $LOGFILE

if grep -q "upgrading" $LOGFILE; then
  echo "Rebooting due to package updates"
  sudo reboot
  exit 0
fi

echo "No reboot necessary"
exit 0
