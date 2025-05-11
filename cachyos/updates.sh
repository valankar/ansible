#!/bin/bash
set -e

LOGFILE="$HOME/bin/updates.log"
yay --noconfirm --noprogressbar | tee $LOGFILE

if grep -q "nothing to do" $LOGFILE; then
  echo "No reboot necessary"
  exit 0
fi

echo "Rebooting due to package updates"
sudo reboot
