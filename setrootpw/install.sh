#!/usr/bin/env ash

if [ "${1}" = "late" ]; then
  echo "Installing addon setrootpw - ${1}"
  mkdir -p "/tmpRoot/usr/arc/addons/"
  cp -vf "${0}" "/tmpRoot/usr/arc/addons/"

  mkdir -p /tmpRoot/usr/lib/openssh
  cp -vf /usr/lib/openssh/sftp-server /tmpRoot/usr/lib/openssh/sftp-server

  FILE="/tmpRoot/etc/ssh/sshd_config"
  [ ! -f "${FILE}.bak" ] && cp -f "${FILE}" "${FILE}.bak"

  SED_PATH='/tmpRoot/usr/bin/sed'
  cp -f "${FILE}.bak" "${FILE}"
  ${SED_PATH} -i 's|^.*PermitRootLogin.*$|PermitRootLogin yes|' ${FILE}
  ${SED_PATH} -i 's|^Subsystem.*$|Subsystem	sftp	/usr/lib/openssh/sftp-server|' ${FILE}

  if [ ! -f /tmpRoot/usr/syno/etc/esynoscheduler/esynoscheduler.db ]; then
    echo "copy esynoscheduler.db"
    mkdir -p /tmpRoot/usr/syno/etc/esynoscheduler
    cp -vf /addons/esynoscheduler.db /tmpRoot/usr/syno/etc/esynoscheduler/esynoscheduler.db
  fi
  echo "insert setrootpw task to esynoscheduler.db"
  export LD_LIBRARY_PATH=/tmpRoot/bin:/tmpRoot/lib
  /tmpRoot/bin/sqlite3 /tmpRoot/usr/syno/etc/esynoscheduler/esynoscheduler.db <<EOF
DELETE FROM task WHERE task_name LIKE 'SetRootPw';
INSERT INTO task VALUES('SetRootPw', '', 'bootup', '', 0, 0, 0, 0, '', 0, '
PW=""    # Please change to the password you need.
if [ -n "\${PW}" ]; then
  /usr/syno/sbin/synouser --setpw root \${PW}
  systemctl restart sshd
  synowebapi --exec api=SYNO.Core.Terminal method=set version=3 enable_ssh=true ssh_port=22
fi
', 'script', '{}', '', '', '{}', '{}');
EOF
elif [ "${1}" = "uninstall" ]; then
  echo "Installing addon setrootpw - ${1}"

  rm -f /tmpRoot/usr/lib/openssh/sftp-server

  FILE="/tmpRoot/etc/ssh/sshd_config"
  [ -f "${FILE}.bak" ] && mv -f "${FILE}.bak" "${FILE}"

  if [ -f /tmpRoot/usr/syno/etc/esynoscheduler/esynoscheduler.db ]; then
    echo "delete setrootpw task from esynoscheduler.db"
    export LD_LIBRARY_PATH=/tmpRoot/bin:/tmpRoot/lib
    /tmpRoot/bin/sqlite3 /tmpRoot/usr/syno/etc/esynoscheduler/esynoscheduler.db <<EOF
DELETE FROM task WHERE task_name LIKE 'SetRootPw';
EOF
  fi
fi
