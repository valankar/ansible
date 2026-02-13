#!/bin/bash
set -e

if systemctl list-unit-files kopia.service >/dev/null; then
  echo "Running kopia"
  sudo systemctl start kopia
fi

LOGFILE="$HOME/bin/updates.log"
yes | arch-update 2>&1 | tee $LOGFILE

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
