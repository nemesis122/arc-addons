#!/usr/bin/env ash

if [ "${1}" = "patches" ]; then
    echo "Installing addon nvmeinstall - ${1}"

    # Add NVMe disks to installable_disk_list - https://jim-plus.translate.goog/blog/post/jim/synology-installation-with-nvme-disks-only?_x_tr_sl=zh-CN&_x_tr_tl=en&_x_tr_hl=en&_x_tr_pto=sc
    # DSM 7.2.1
    matches_nvme_add=$(xxd -p /usr/syno/bin/scemd | tr -d '\n' | grep -o '4584ed74b7488b4c24083b01' | wc -l)
    if [ "${matches_nvme_add}" == "1" ]; then
        [ ! -f /usr/syno/bin/scemd.syno ] && cp /usr/syno/bin/scemd /usr/syno/bin/scemd.syno
        xxd -p /usr/syno/bin/scemd.syno | tr -d '\n' | sed 's/4584ed74b7488b4c24083b01/4584ed75b7488b4c24083b01/g' | xxd -r -p - /usr/syno/bin/scemd
    fi
    # Modify linuxrc.syno.impl
    cp -vf "/linuxrc.syno.impl" "/linuxrc.syno.impl.syno"
    sed -i 's/WithInternal=0/WithInternal=1/g' /linuxrc.syno.impl
    # Only return NVMe disks as installable_disk_list and pretend to be SATA
    mv -f /usr/syno/bin/synodiskport /usr/syno/bin/synodiskport.syno
    mv -f /usr/syno/bin/synodiskport.nvme /usr/syno/bin/synodiskport
elif [ "${1}" = "late" ]; then
    echo "Installing addon nvmeinstall - ${1}"

    # Disable NVMe resetting hibernation timer - https://www.reddit.com/r/synology/comments/129lzjg/fixing_hdd_hibernation_when_you_have_docker_on/
    # DSM 7.2.1
    matches_hiber_nvme=$(xxd -p /tmpRoot/usr/syno/bin/scemd | tr -d '\n' | grep -o '4889eebf0100000048890424e8bfd1feff4889eebf0200000089c3e8b0d1feff4889eebf07000000e8a3d1feff85db' | wc -l)
    if [ "${matches_hiber_nvme}" == "1" ]; then
        [ ! -f /tmpRoot/usr/syno/bin/scemd.syno ] && cp /tmpRoot/usr/syno/bin/scemd /tmpRoot/usr/syno/bin/scemd.syno
        xxd -p /tmpRoot/usr/syno/bin/scemd | tr -d '\n' | sed 's/4889eebf0100000048890424e8bfd1feff4889eebf0200000089c3e8b0d1feff4889eebf07000000e8a3d1feff85db/4889eebf0100000048890424e8bfd1feff4889eebf0200000089c3e8b0d1feff4889eebf0b000000e8a3d1feff85db/g' | xxd -r -p - /tmpRoot/usr/syno/bin/scemd
    fi
    # Fix SMART check waking up SATA disks - https://www.reddit.com/r/synology/comments/129lzjg/fixing_hdd_hibernation_when_you_have_docker_on/
    # DSM 7.2.1
    matches_hiber_smart=$(xxd -p /tmpRoot/usr/syno/sbin/synostoraged | tr -d '\n' | grep -o '4889debf03000000e82778ffff85c00f886f0100004889debf07000000e81278ffff85c00f88300100004889debf0b000000e8' | wc -l)
    if [ "${matches_hiber_smart}" == "1" ]; then
        [ ! -f /tmpRoot/usr/syno/sbin/synostoraged.syno ] && cp /tmpRoot/usr/syno/sbin/synostoraged /tmpRoot/usr/syno/sbin/synostoraged.syno
        xxd -p /tmpRoot/usr/syno/sbin/synostoraged | tr -d '\n' | sed 's/4889debf03000000e82778ffff85c00f886f0100004889debf07000000e81278ffff85c00f88300100004889debf0b000000e8/4889debf03000000e82778ffff85c00f886f010000eb13debf07000000e81278ffff85c00f88300100004889debf0b000000e8/g' | xxd -r -p - /tmpRoot/usr/syno/sbin/synostoraged
    fi
    # Suppress "system partion failure" warning
    # DSM 7.2.1
    matches_sys_fail=$(xxd -p /tmpRoot/usr/lib/libhwcontrol.so.1 | tr -d '\n' | grep -o '73797374656d5f6372617368656400' | wc -l)
    if [ "${matches_sys_fail}" == "1" ]; then
        [ ! -f /tmpRoot/usr/lib/libhwcontrol.so.1.syno ] && cp /tmpRoot/usr/lib/libhwcontrol.so.1 /tmpRoot/usr/lib/libhwcontrol.so.1.syno
        xxd -p /tmpRoot/usr/lib/libhwcontrol.so.1 | tr -d '\n' | sed 's/73797374656d5f6372617368656400/6e6f726d616c006372617368656400/g' | xxd -r -p - /tmpRoot/usr/lib/libhwcontrol.so.1
    fi
    # Update StorageManager to show NVMe disks
    # DSM 7.2.1
    matches_nvme_show=$(xxd -p /tmpRoot/usr/local/packages/@appstore/StorageManager/ui/storage_panel.js | grep -o 'if("disabled"===e.portType||e.isCacheTray())' | wc -l)
    if [ "${matches_nvme_show}" == "1" ]; then
        sed -i 's/if("disabled"===e.portType||e.isCacheTray())/if("disabled"===e.portType)/g' /tmpRoot/usr/local/packages/@appstore/StorageManager/ui/storage_panel.js
    fi
    # Add service to sync sata disks at shutdown
    cp -vf /usr/sbin/md0sync.sh /tmpRoot/usr/sbin/md0sync.sh
    DEST="/tmpRoot/lib/systemd/system/md0sync.service"
    echo "[Unit]"                                            >${DEST}
    echo "Description=Sync /dev/md0 with all disks"         >>${DEST}
    echo "After=syno-md-resync-speed-adjust@active.service" >>${DEST}
    echo                                                    >>${DEST}
    echo "[Service]"                                        >>${DEST}
    echo "Type=oneshot"                                     >>${DEST}
    echo "RemainAfterExit=yes"                              >>${DEST}
    echo "ExecStart=/bin/true"                              >>${DEST}
    echo "ExecStop=/usr/sbin/md0sync.sh"                    >>${DEST}
    echo                                                    >>${DEST}
    echo "[Install]"                                        >>${DEST}
    echo "WantedBy=default.target"                          >>${DEST}
    mkdir -vp /tmpRoot/lib/systemd/system/default.target.wants
    ln -vsf /lib/systemd/system/md0sync.service /tmpRoot/lib/systemd/system/default.target.wants/md0sync.service
fi