# SPDX-License-Identifier: Apache-2.0
class ceph::osds (
    String                        $fsid,
    Hash[String, Hash]            $mon_hosts,
    Boolean                       $discrete_bluestore_device = false,
    Optional[Hash[String, Hash]]  $osd_hosts                 = undef,
    Optional[Array[String]]       $absent_osds               = undef,
    Optional[Array[String]]       $excluded_slots            = undef,
    Optional[String]              $bluestore_device_name     = undef,
) {
    Ceph::Auth::Keyring['admin'] -> Class['ceph::osds']
    Ceph::Auth::Keyring['bootstrap-osd'] -> Class['ceph::osds']
    Ceph::Auth::Keyring["osd.${facts['hostname']}"] -> Class['ceph::osds']
    Class['ceph::config'] -> Class['ceph::osds']

    ensure_packages(['ceph-osd','ceph-volume','hdparm'])

    # Disable the write cache on devices using the SCSI disk driver
    $facts['disk_type'].filter | $disk | { $disk[0] =~ 'sd*' }.each |$disk, $type| {
    # Unset wite cache
    exec { "Disable write cache on device /dev/${disk}":
        # 0->disable, 1->enable
        command => "hdparm -W 0 /dev/${disk}",
        user    => 'root',
        unless  => "hdparm -W /dev/${disk} | grep write-caching | egrep '(not supported|off)'",
        path    => ['/usr/sbin', '/usr/bin'],
    }

    # Set io scheduler on disks
    # hdd -> mq-deadline
    # ssd/nvme -> none
    if ($type == 'ssd') {
        $disk_io_scheduler = 'none'
    } elsif ($type == 'hdd') {
        $disk_io_scheduler = 'mq-deadline'
    } else {
        fail("${type} for /dev/${disk} is currently not managed")
    }

    # The device names /dev/sd* may be volatile, but if they change this will detect it
    # and refresh the sysfsutils service on first puppet run after boot.
    sysfs::parameters { "scheduler_${disk}":
        priority => 90,
        values   => {
            "block/${disk}/queue/scheduler" => $disk_io_scheduler,
        },
    }
  }

  # Create a new hash with the populated slots from all controllers, exclude any that are in the list of excluded slots.
  # This mechanism is intended to be used to avoid adding an OSD for the operating system disks.
  #
  # n.b. The ceph_disks fact is not available until after the first puppet run, so this conditional will defer management
  # of the OSDs until the second puppet run. This is a temporary measure to fix reimages.
  if $facts['ceph_disks'] {
    $storage_disks = $facts['ceph_disks'].values.map | $controller | {
        $controller['disks']
    }.reduce | $memo, $disk | {
        $memo + $disk
    }.filter | $slot | {
        ! ($slot[0] in $excluded_slots)
    }
  }
  else {
    $storage_disks = {}
  }

  # Optional support for creating bluestore partitions on a named NVMe device
    if ( $discrete_bluestore_device and $bluestore_device_name =~ '\/dev\/nvme[0-9]*n[0-9]*' ) {
        ensure_packages(['parted'])

        # Set gpt partition table
        exec { "Create gpt label on ${bluestore_device_name}":
            command => "parted -s -a optimal ${bluestore_device_name} mklabel gpt",
            user    => 'root',
            unless  => "parted -s ${bluestore_device_name} print|grep \"Partition Table: gpt\"",
            path    => ['/usr/sbin', '/usr/bin'],
        }

        # Filter the list of storage disks to obtain a list of HDDs that are to be used for hosting an OSD,
        # then partition the given device equally between the number of HDDs.
        $hdd_storage_disks = $storage_disks.values.filter | $disk | { $disk['medium'] == 'HDD' }

        $percent_partition = 100 / $hdd_storage_disks.length

        $hdd_storage_disks.each |$index, $hdd_disk| {
            $start_partition = 0 + $index * $percent_partition
            $end_partition = ($index +1) * $percent_partition
            $hdd_disk_label = "c${hdd_disk['controller']}e${hdd_disk['enclosure']}s${hdd_disk['slot']}"

            exec { "Create partition db.${hdd_disk_label} on ${bluestore_device_name}":
                command => "parted -s -a optimal ${bluestore_device_name} mkpart db.${hdd_disk_label} ext4 ${start_partition}% ${end_partition}%",
                user    => 'root',
                unless  => "parted -s ${bluestore_device_name} print|grep db.${hdd_disk_label}",
                path    => ['/usr/sbin', '/usr/bin'],
            }
        }
    }

    # Create the OSD devices - We use the wwn here because it will always refer to the same drive.
    # It is not safe to depend on the device name /dev/sd* remaining the same across reboots.
    $storage_disks.each |$slot_id, $disk| {
        # Construct a name for the osd based on its controller, enclosure, and slot values.
        $osd_label = "c${disk['controller']}e${disk['enclosure']}s${disk['slot']}"

        # If this is a hard drive and we have specified that discrete bluestore partitions
        # are in use, then use its named partition for the bluestore db.
        if ($disk['medium'] == 'HDD') and $discrete_bluestore_device {
            $bluestore_db = "/dev/disk/by-partlabel/db.${osd_label}"
        } else {
            $bluestore_db = undef
        }

        # For a SATA disk the WWN reported by the perccli64 tool matches that reported by the kernel in /dev/disk/by-id/wwwn-0x*.
        # For a SAS hard drive we need to increment the hex string reported by three bits to obtain the LUN.
        # For a SAS sold-state drive we need to increment the hex string by one bit to obtain the first SAS port.
        # In order to handle this we convert the wwn to a decimal, add zero, one, or three bits, then convert it back to hexadecimal in lowercase.
        $sas_disk = bool2num($disk['interface'] == 'SAS')
        $wwn_bitshift = $disk['medium'] ? {
            'SSD' => $sas_disk,
            'HDD' => $sas_disk * 3,
        }
        $wwid = String.new(Integer.new("0x${disk['wwn']}")+$wwn_bitshift,'%#x')

        # This device name will always be a symlink from the disk with this WWN to its current /dev/sd* name, as managed by udev.
        # The links are always in lower case, whereas the WWN reported by the perccli64 tool is in upper case.
        $device = "/dev/disk/by-id/wwn-${wwid}"

        # Use the medium in the ceph_disks fact to inform the ceph-volume tool of its device class at the time of OSD creation.
        $device_class = $disk['medium'].downcase

        # Check to see if the current disk is marked for removal. This is intended to support replacement of failed OSDs
        # by temporarily absenting them. As opposed to $excluded_slots which is for permanently ignoring certain slots such as
        # those used for holding the O/S.
        $ensure_osd = ($osd_label in $absent_osds).bool2str('absent', 'present')

        ceph::osd { $osd_label:
            ensure       => $ensure_osd,
            fsid         => $fsid,
            device       => $device,
            device_class => $device_class,
            bluestore_db => $bluestore_db,
        }
    }
}
