#!/usr/bin/env ash

MODELS="SA6400"
MODEL="$(cat /proc/sys/kernel/syno_hw_version)"

if ! echo "${MODELS}" | grep -q "${MODEL}"; then
  echo "${MODEL} is not supported"
  exit 0
fi

if [ "${1}" = "early" ]; then
  echo "Installing addon nvmesystem - ${1}"

  # System volume is assembled with SSD Cache only, please remove SSD Cache and then reboot
  sed -i "s/support_ssd_cache=.*/support_ssd_cache=\"no\"/" /etc/synoinfo.conf /etc.defaults/synoinfo.conf

  # [CREATE][failed] Raidtool initsys
  SO_FILE="/usr/syno/bin/scemd"
  [ ! -f "${SO_FILE}.bak" ] && cp -vf "${SO_FILE}" "${SO_FILE}.bak"
  cp -f "${SO_FILE}" "${SO_FILE}.tmp"
  xxd -c $(xxd -p "${SO_FILE}.tmp" 2>/dev/null | wc -c) -p "${SO_FILE}.tmp" 2>/dev/null |
    sed "s/dcfcffff4584ed74b7488b4c24083b01/dcfcffff4584ed75b7488b4c24083b01/" |
    xxd -r -p >"${SO_FILE}" 2>/dev/null
  rm -f "${SO_FILE}.tmp"

elif [ "${1}" = "late" ]; then
  echo "Installing addon nvmesystem - ${1}"
  mkdir -p "/tmpRoot/usr/arc/addons/"
  cp -vf "${0}" "/tmpRoot/usr/arc/addons/"

  # disk/shared_disk_info_enum.c::84 Failed to allocate list in SharedDiskInfoEnum, errno=0x900.
  SO_FILE="/tmpRoot/usr/lib/libhwcontrol.so.1"
  [ ! -f "${SO_FILE}.bak" ] && cp -vf "${SO_FILE}" "${SO_FILE}.bak"

  cp -vf "${SO_FILE}" "${SO_FILE}.tmp"
  xxd -c $(xxd -p "${SO_FILE}.tmp" 2>/dev/null | wc -c) -p "${SO_FILE}.tmp" 2>/dev/null |
    sed "s/0f95c00fb6c0488b9424081000006448/0f94c00fb6c0488b9424081000006448/; s/ffff89c18944240c8b44240809e84409/ffff89c18944240c8b44240890904409/" |
    xxd -r -p >"${SO_FILE}" 2>/dev/null
  rm -f "${SO_FILE}.tmp"

  # Create storage pool page without RAID type.
  cp -vf /usr/bin/nvmesystem.sh /tmpRoot/usr/bin/nvmesystem.sh

  DEST="/tmpRoot/usr/lib/systemd/system/nvmesystem.service"
  echo "[Unit]"                                          >${DEST}
  echo "Description=Modify storage panel"               >>${DEST}
  echo "After=multi-user.target"                        >>${DEST}
  echo "Wants=storagepanel.service"                     >>${DEST}  # storagepanel
  echo "After=storagepanel.service"                     >>${DEST}  # storagepanel
  echo                                                  >>${DEST}
  echo "[Service]"                                      >>${DEST}
  echo "Type=oneshot"                                   >>${DEST}
  echo "RemainAfterExit=yes"                            >>${DEST}
  echo "ExecStart=/usr/bin/nvmesystem.sh"               >>${DEST}
  echo                                                  >>${DEST}
  echo "[Install]"                                      >>${DEST}
  echo "WantedBy=multi-user.target"                     >>${DEST}

  mkdir -vp /tmpRoot/lib/systemd/system/multi-user.target.wants
  ln -vsf /usr/lib/systemd/system/nvmesystem.service /tmpRoot/lib/systemd/system/multi-user.target.wants/nvmesystem.service

elif [ "${1}" = "uninstall" ]; then
  echo "Installing addon nvmesystem - ${1}"

  SO_FILE="/tmpRoot/usr/lib/libhwcontrol.so.1"
  [ -f "${SO_FILE}.bak" ] && mv -f "${SO_FILE}.bak" "${SO_FILE}"

  rm -f "/tmpRoot/lib/systemd/system/multi-user.target.wants/nvmesystem.service"
  rm -f "/tmpRoot/usr/lib/systemd/system/nvmesystem.service"

  [ ! -f "/tmpRoot/usr/arc/revert.sh" ] && echo '#!/usr/bin/env bash' >/tmpRoot/usr/arc/revert.sh && chmod +x /tmpRoot/usr/arc/revert.sh
  echo "/usr/bin/nvmesystem.sh -r" >>/tmpRoot/usr/arc/revert.sh
  echo "rm -f /usr/bin/nvmesystem.sh" >>/tmpRoot/usr/arc/revert.sh
fi
