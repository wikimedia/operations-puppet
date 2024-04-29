# SPDX-License-Identifier: Apache-2.0
#
# == Define: ceph::osd
#
# This defined type installs and configures a ceph object storage daemon (OSD)
#
# === Parameters:
#
# [*title*] The name of the OSD resource.
#   Mandatory. This takes the form c0e23s0 indicating the
#   controller, enclosure, and slot of the storage device.
#
# [*ensure*] Installs ( present ) or remove ( absent ) an OSD
#   Optional. Defaults to present.
#   If set to absent, it will stop the OSD service and remove
#   the associated data directory.
#
# [*fsid*] The ceph cluster FSID
#
# [*device*] This is the device name that is used as the backing device for the
#   OSD. It is provided as the symlink using the wwn value in `/dev/disk/by-id/`
#
# [*device_class*] This is used in the CRUSH maps to inform the ceph-volume tool
#   as to whether the device is a hard drive or a solid state drive. Values: hdd/ssd
#
# [*bluestore_db*] The OSD bluestore DB path (WAL will be collocated with DB).
#   Optional. Defaults to co-locating the DB and WAL with the data device.
#
# [*exec_timeout*] The default exec resource timeout, in seconds
#   Optional. Defaults to 600
#
define ceph::osd (
    Wmflib::Ensure    $ensure       = present,
    String            $fsid         = undef,
    String            $device       = undef,
    Enum['ssd','hdd'] $device_class = undef,
    Optional[String]  $bluestore_db = undef,
    Integer           $exec_timeout = 600,
    ) {
    unless $ensure == 'absent' or ($fsid and $device_class) {
      fail('Description, fsid and device_class parameters are mandatory for ensure != absent')
    }

    # If a DB device is specified, the WAL will be explicitly colocated with the DB on the faster device.
    if $bluestore_db {
        $bluestore_opts = "--block.db ${bluestore_db}"
    } else {
        $bluestore_opts = ''
    }

    if $ensure == 'present' {
        # These will be the names of the exec resources
        # $check_fsid_mismatch = "ceph-osd-check-fsid-mismatch-${name}"
        $prepare = "ceph-osd-prepare-${name}"
        $activate = "ceph-osd-activate-${name}"

        # Ensure that all OSDs are prepared before any are activated
        Exec<| tag == 'prepare' |> -> Exec<| tag == 'activate' |>

        # TODO: Disabling fsid mismatch check for now, until we can refactor
        # Check for any fsid mismatch before running any prepare operations
        # Exec[$check_fsid_mismatch] -> Exec[$prepare]

        # We want this exec to exit with an error and prevent any further osd operations if there is an fsid mismatch
        # $check_fsid_command = 'exit 1'

        # return error if $(readlink -f ${device}) has fsid differing from ${fsid}, unless there is no fsid
        # $check_fsid_unless = @("COMMAND"/L$)
        # if [ -z $(ceph-volume lvm list ${device} --format=json | jq -r '.[]|.[]|.tags|."ceph.osd_fsid"') ]; then exit 0 ; fi \
        # test ${fsid} = $(ceph-volume lvm list ${device} --format=json | jq -r '.[]|.[]|.tags|."ceph.osd_fsid"')
        # | -COMMAND

        # exec { $check_fsid_mismatch:
        #     command   => $check_fsid_command,
        #     unless    => $check_fsid_unless,
        #     provider  => 'shell',
        #     path      => '/usr/bin:/bin:/usr/sbin:/sbin',
        #     logoutput => true,
        #     timeout   => $exec_timeout,
        # }

        # Prepare OSD
        $prepare_command = "ceph-volume lvm prepare --bluestore --data ${device} ${bluestore_opts} --crush-device-class ${device_class}"
        $prepare_unless = "ceph-volume lvm list ${device}"

        exec { $prepare:
            command   => $prepare_command,
            unless    => $prepare_unless,
            provider  => 'shell',
            path      => '/usr/bin:/bin:/usr/sbin:/sbin',
            logoutput => true,
            timeout   => $exec_timeout,
            tag       => 'prepare',
        }

        # Activate osd
        $activate_command = @("COMMAND"/L$)
        id=$(ceph-volume lvm list ${device} --format=json | jq -r keys[]) && \
        fsid=$(ceph-volume lvm list ${device} --format=json | jq -r '.[]|.[]|.tags|."ceph.osd_fsid" // empty') &&\
        ceph-volume lvm activate \$id \$fsid
        | -COMMAND

        $activate_unless = @("COMMAND"/L$)
        id=$(ceph-volume lvm list ${device} --format=json | jq -r keys[]) && \
        systemctl is-active ceph-osd@\$id
        | -COMMAND

        exec { $activate:
            command   => $activate_command,
            unless    => $activate_unless,
            provider  => 'shell',
            path      => '/usr/bin:/bin:/usr/sbin:/sbin',
            logoutput => true,
            timeout   => $exec_timeout,
            tag       => 'activate',
        }
    } elsif $ensure == 'absent' {
        $remove = "ceph-osd-remove-${name}"
        $remove_command = @("COMMAND"/L$)
        id=$(ceph-volume lvm list ${device} --format=json | jq -r keys[]) && \
        if [[ \$id ]] && [[ \$id =~ ^[0-9]+\$ ]] ; then \
            ceph osd ok-to-stop osd.\$id && \
            ceph osd safe-to-destroy osd.\$id && \
            { systemctl stop ceph-osd@\$id || true; } && \
            ceph osd crush remove osd.\$id && \
            ceph auth del osd.\$id && \
            ceph osd purge \$id --yes-i-really-mean-it && \
            { umount /var/lib/ceph/osd/ceph-\$id || true; } && \
            rm -fr /var/lib/ceph/osd/ceph-\$id && \
            ceph-volume lvm zap ${device} --destroy \
        fi
        | -COMMAND

        $remove_onlyif = "ceph-volume lvm list ${device}"

        exec { "remove-osd-${name}":
            command   => $remove_command,
            onlyif    => $remove_onlyif,
            provider  => 'shell',
            path      => '/usr/bin:/bin:/usr/sbin:/sbin',
            logoutput => true,
            timeout   => $exec_timeout,
        }
    }
}
