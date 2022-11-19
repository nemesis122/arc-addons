#!/usr/bin/env ash

if [ "${1}" = "late" ]; then
  echo "Installing Patch for Disksleep"
  tar -zxvf /addons/sleepdisks.tgz -C /tmpRoot/
  chmod 755 /tmpRoot/usr/bin/sleepdisks
  chmod 644 /tmpRoot/usr/lib/systemd/system/sleepdisks.service
  ln -sf /usr/lib/systemd/system/sleepdisks.service /tmpRoot/etc/systemd/system/multi-user.target.wants/sleepdisks.service
fi
