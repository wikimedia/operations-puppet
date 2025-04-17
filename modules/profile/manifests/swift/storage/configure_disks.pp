# SPDX-License-Identifier: Apache-2.0
# @summary create the filesystems and mount points for swift storage
# @param swift_storage_dir the base directory for swift storage
class profile::swift::storage::configure_disks (
    Stdlib::Unixpath $swift_storage_dir = lookup('profile::swift::storage::configure_disks::swift_storage_dir'),
) {
    if !$facts.has_key('swift_disks') {
        fail('unable to find swift_disk fact')
    }
    ['accounts', 'container'].each |$storage_type| {
        unless $facts['swift_disks'][$storage_type].size == 2 {
            fail("Not enough ${storage_type} partitions")
        }
        $facts['swift_disks'][$storage_type].sort.each |$partition| {
            # disk is of the form pci-0000:3b:00.0-scsi-0:0:1:0-part4
            # or (SM systems) pci-0000:00:11.5-ata-1.0-part4
            # The system disks are always the last two disks so to avoid having them numbered
            # 12,13 or 23,24 depending on the model we mod 2 them to get them to 0, 1
            # .match returns the whole matching string, and then the matched group(s)
            $idx = String(Integer($partition.match(/(\d+)(:|.)0-part\d/)[1]) % 2)
            $partition_path = "/dev/disk/by-path/${partition}"
            $mount_point = "${swift_storage_dir}${$storage_type}${idx}"
            swift::mount_filesystem { $partition_path:
                use_label            => false,
                mount_point_override => $mount_point,
            }
        }
    }
    # TODO: why start at 1M, copied from swift::init_device
    $parted_script = 'mklabel gpt mkpart primary 1M 100%'
    $facts['swift_disks']['objects'].each |$drive| {
        # disk is of the form pci-0000:3b:00.0-scsi-0:0:1:0
        # or pci-0000:98:00.0-sas-exp0x500304801ff9b73f-phy0-lun-0
        $sas_id = $drive =~ /exp0x([0-9a-z]+)-phy(\d+)-lun/ ? {
            true    => "_exp_${1}_phy_${2}",
            default => undef,
        }
        if $sas_id != undef {
            $idx = $sas_id
        } else {
            $idx = $drive.split(/:/)[-2]
        }
        $device_path = "/dev/disk/by-path/${drive}"
        $partition_path = "${device_path}-part1"
        $swift_path = "${swift_storage_dir}${drive}-part1"

        exec { "parted-${drive}":
            command => "/usr/sbin/parted --script --align optimal ${device_path} -- ${parted_script}",
            creates => $partition_path,
        }
        # rebuild everything to switch to this new way.
        exec { "mkfs-${drive}":
            # Disable free inode b-tree, see T199198
            command => "/usr/sbin/mkfs -t xfs -m crc=1 -m finobt=0 -i size=512 ${partition_path}",
            unless  => "/usr/sbin/blkid -o value -s TYPE ${partition_path} | /usr/bin/grep -qE '\\bxfs\\b'",
            require => [
                Package['xfsprogs'],
                Exec["parted-${drive}"],
            ],
        }
        $mount_point = "${swift_storage_dir}objects${idx}"
        swift::mount_filesystem { $partition_path:
            use_label            => false,
            mount_point_override => $mount_point,
            require              => Exec["mkfs-${drive}"],
        }
    }
}
