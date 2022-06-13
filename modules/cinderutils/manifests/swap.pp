# SPDX-License-Identifier: Apache-2.0
# = define: cinderutils::swap
# Detects an available volume and creates it as swap space
#
# == Parameters
#
# [*min_gb*]
#   When detecting a volume to use as swap, only use volumes at least this size
# [*max_gb*]
#   When detecting a volume to use as swap, only use volumes no larger than this
#
define cinderutils::swap(
    $min_gb,
    $max_gb,
) {
    $swap_volume = $facts['block_devices'].reduce(undef) |$memo, $volume| {
        if $volume['fstype'] == 'swap' {
            # There's already a swap partition! Let's grab the biggest one
            $mount_requires = []
            if $memo != undef and $memo['size'] > $volume['size'] {
                $memo
            } else {
                $volume
            }
        } elsif (!$memo and
                  !$volume['fstype'] and
                  $volume['dev'] != 'vda' and
                  $volume['dev'] != 'sda' and
                  $volume['type'] == 'disk' and
                  $volume['size'] >= $min_gb * 1024 * 1024 * 1024 and
                  $volume['size'] <= $max_gb * 1024 * 1024 * 1024) {
            # This is a candidate to make into swap if we don't already
            #  have something formatted as swap.
            $mount_requires = [Exec["format-${name}"]]
            $volume
        } else {
            $memo
        }
    }

    if $swap_volume == undef {
        fail("Unable to locate a swap volume.  Please attach a cinder volume or use a flavor with a swap partition.\nThe swap volume or partition must be at least ${min_gb}GB and no larger than ${max_gb}GB\n")
    }

    # Support legacy dev names from lvm
    $swap_dev_path = regsubst($swap_volume['dev'],'^vd-','vd/')

    if !$swap_volume['fstype'] {
        exec { "format-${name}":
            command     => "/sbin/mkswap /dev/${swap_dev_path}",
        }
    }

    mount { "mount-swap-${name}":
        ensure  => present,
        name    => '-',
        atboot  => true,
        device  => "/dev/${swap_dev_path}",
        options => 'defaults',
        fstype  => 'swap',
        require => $mount_requires,
        notify  => Exec["swapon-${name}"],
    }

    exec { "swapon-${name}":
        refreshonly => true,
        command     => "/sbin/swapon /dev/${swap_dev_path}",
    }
}
