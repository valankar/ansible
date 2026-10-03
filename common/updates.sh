#!/bin/bash
set -e

notification_bus="org.freedesktop.Notifications"
notification_path="/org/freedesktop/Notifications"

# Create notification
if pgrep plasmashell >/dev/null; then
  export DISPLAY=:0
  export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus
  KDE_RUNNING=true
  notification_id=$(gdbus call --session \
    --dest "$notification_bus" \
    --object-path "$notification_path" \
    --method "$notification_bus.Notify" \
    "$0" 0 "" "Updates in progress" "Please wait..." \
    '[]' '{}' 0 | grep -oP '(?<=uint32 )\d+')
fi

until host google.com &>/dev/null; do
  echo "Waiting for DNS..."
  sleep 2
done
if systemctl list-unit-files kopia.service >/dev/null; then
  echo "Running kopia"
  until sudo systemctl start kopia; do
    echo "Kopia failed. Waiting."
    sleep 30
  done
fi

LOGFILE="$HOME/bin/updates.log"
rm -f $LOGFILE
if command -v flatpak >/dev/null; then
  sudo flatpak update --noninteractive -y 2>&1 | tee -a $LOGFILE
fi
paru -Syu --noconfirm --noprogressbar 2>&1 | tee -a $LOGFILE
# Remove orphans
if orphans=$(paru -Qdtq); then
  if [ -n "$orphans" ]; then
    paru -Rns --noconfirm $orphans 2>&1 | tee -a $LOGFILE
  fi
fi
# Cleanup cache
yes | paru -Scc 2>&1 | tee -a $LOGFILE
sudo rm -rf /var/cache/pacman/pkg/download-*

URL=""
if [ -n "$URL" ]; then
  curl -fsS -m 10 --retry 5 -o /dev/null $URL
fi
if grep -q "upgrading" $LOGFILE; then
  echo "Rebooting due to package updates"
  if [[ -v KDE_RUNNING ]]; then
    if gdbus call --session --dest org.kde.Shutdown --object-path /Shutdown --method org.kde.Shutdown.logoutAndReboot; then
      exit 0
    fi
  fi
  sudo reboot
  exit 0
fi

echo "No reboot necessary"
# Close notification
if [[ -v KDE_RUNNING ]]; then
  gdbus call --session \
    --dest "$notification_bus" \
    --object-path "$notification_path" \
    --method "$notification_bus.CloseNotification" "$notification_id"
fi
exit 0
