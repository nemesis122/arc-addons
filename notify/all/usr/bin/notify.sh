#!/usr/bin/env bash

if [ "${1}" = "-r" ]; then
  TEXTS_PATH="/usr/local/share/notification/arc"
  CACHE_PATH="/var/cache/texts/arc"
  [ -d "${TEXTS_PATH}" ] && rm -rf "${TEXTS_PATH}"
  [ -d "${CACHE_PATH}" ] && rm -rf "${CACHE_PATH}"
  /usr/syno/bin/notification_utils --remove_category_db_file arc
  /usr/syno/bin/notification_utils --sync_setting_db
else
  TEXTS_PATH="/usr/local/share/notification/arc"
  CACHE_PATH="/var/cache/texts/arc"
  for F in $(ls "/usr/syno/synoman/webman/texts" 2>/dev/null); do
    rm -rf "${TEXTS_PATH}/${F}"
    mkdir -p "${TEXTS_PATH}/${F}"
    echo -en '[arc_notify]\nCategory: System\nLevel: NOTIFICATION_INFO\nDesktop: %NOTIFICATION%\n\n\n' >>"${TEXTS_PATH}/${F}/mails"
    echo -en '[arc_notify_subject]\nCategory: System\nLevel: NOTIFICATION_INFO\nDesktop: %NOTIFICATION%\nSubject: %NOTIFICATION%\n\n%SUBJECT%\n\nFrom %HOSTNAME%\n\n\n' >>"${TEXTS_PATH}/${F}/mails"
  done
  /bin/rm -rf "${CACHE_PATH}"
  /bin/mkdir -p /var/cache/texts
  /bin/rsync -ar "${TEXTS_PATH}/" "${CACHE_PATH}"
  /usr/syno/bin/notification_utils --remove_category_db_file arc
  /usr/syno/bin/notification_utils --gen_category_db_file arc enu
  /usr/syno/bin/notification_utils --sync_setting_db

  # NOTIFICATION="Arc Notification"
  # synodsmnotify -e false -b false "@administrators" "arc_notify" "{\"%NOTIFICATION%\": \"${NOTIFICATION}\"}"
  NOTIFICATION="Arc Loader Notification"
  SUBJECT="$(cat <<EOF
<p>Welcome to <a href="https://github.com/AuxXxilium" target="_blank">Arc</a> Loader!</p>
<p></p>
<p>You have successfully installed Synology DSM on your System.</p>
<p></p>
<p>If you encounter any issues, please read <a href="https://github.com/AuxXxilium/AuxXxilium/wiki" target="_blank">Wiki</a> first.</p>
<p>Feel free to join our <a href="https://discord.gg/auxxxilium" target="_blank">Discord</a>.</p>
<p></p>
<p>To reboot to Config Mode, you can enable SSH and do: loader-reboot.sh config</p>
<p>Open VM Tools for ESXI can be found at <a href="https://github.com/AuxXxilium/synology-dsm-open-vm-tools" target="_blank">Github / Open VM Tools</a>.</p>
<p>Nvidia Community Driver Package can be found at <a href="https://github.com/pdbear/syno_nvidia_gpu_driver" target="_blank">Github / Syno Nvidia GPU Driver</a>.</p>
EOF
)"
  synodsmnotify -e false -b false "@administrators" "arc_notify_subject" "{\"%NOTIFICATION%\": \"${NOTIFICATION}\", \"%SUBJECT%\": \"${SUBJECT}\"}"
fi
