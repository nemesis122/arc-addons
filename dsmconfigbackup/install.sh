#!/usr/bin/env ash

if [ "${1}" = "late" ]; then
  echo "Installing addon dsmconfigbackup - ${1}"
  mkdir -p "/tmpRoot/usr/arc/addons/"
  cp -vf "${0}" "/tmpRoot/usr/arc/addons/"

  cp -vf /usr/bin/dsmconfigbackup.sh /tmpRoot/usr/bin/dsmconfigbackup.sh
  
  if [ ! -f /tmpRoot/usr/syno/etc/esynoscheduler/esynoscheduler.db ]; then
    echo "copy esynoscheduler.db"
    mkdir -p /tmpRoot/usr/syno/etc/esynoscheduler
    cp -vf /addons/esynoscheduler.db /tmpRoot/usr/syno/etc/esynoscheduler/esynoscheduler.db
  fi
  echo "insert dsmconfigbackup task to esynoscheduler.db"
  export LD_LIBRARY_PATH=/tmpRoot/bin:/tmpRoot/lib
  /tmpRoot/bin/sqlite3 /tmpRoot/usr/syno/etc/esynoscheduler/esynoscheduler.db <<EOF
DELETE FROM task WHERE task_name LIKE 'DsmconfigbackupShutdown';
INSERT INTO task VALUES('DsmconfigbackupShutdown', '', 'shutdown', '', 1, 0, 0, 0, '', 0, "/usr/bin/dsmconfigbackup.sh ${2:-7} ${3:-dsm}_shutdown", 'script', '{}', '', '', '{}', '{}');
EOF
elif [ "${1}" = "uninstall" ]; then
  echo "Installing addon dsmconfigbackup - ${1}"

  rm -f "/tmpRoot/usr/bin/dsmconfigbackup.sh"

  if [ -f /tmpRoot/usr/syno/etc/esynoscheduler/esynoscheduler.db ]; then
    echo "delete dsmconfigbackup task from esynoscheduler.db"
    export LD_LIBRARY_PATH=/tmpRoot/bin:/tmpRoot/lib
    /tmpRoot/bin/sqlite3 /tmpRoot/usr/syno/etc/esynoscheduler/esynoscheduler.db <<EOF
DELETE FROM task WHERE task_name LIKE 'DsmconfigbackupShutdown';
EOF
  fi
fi