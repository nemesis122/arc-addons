#!/usr/bin/env ash

if [ "${1}" = "late" ]; then
  echo "Installing Patch for DriveDB"
  tar -zxvf /addons/drivedb.tgz -C /tmpRoot/
  chmod 755 /tmpRoot/usr/bin/drivedb
  chmod 644 /tmpRoot/usr/lib/systemd/system/drivedb.service
  ln -sf /usr/lib/systemd/system/drivedb.service /tmpRoot/etc/systemd/system/multi-user.target.wants/drivedb.service
fi
