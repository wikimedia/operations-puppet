# resource: cinderutils::ensure
#
# This resource will hunt for an attached but unmounted cinder volume,
#  format it (if necessary), then mount it and add an entry to /etc/fstab
#  so the mount persists through reboots.
#
# For VMs that only use a single attached device this should be reliable and
#  deterministic. For cases that use multiple indentical new volumes it will
#  also be reliable although may require multiple puppet runs to fully stabilize.
#
# Unfortunately we don't have a way to distinguish between attached volumes
#  other than by size. That means that if this class is used to mount volumes
#  that were re-attached after use on a different host, the behavior is somewhat
#  undefined: any volume can get mounted at any of the requested mount points.
#  This can be worked around by mounting the volumes by hand (using prepare_cinder_volume
#  in interactive mode) or by providing size hints via min_gb and max_gb if you need
#  to e.g. mount a small volume at /small and a big volume at /big.
#
# Parameters:
#   mount_point => absolute path to the mount point for the volume.
#                  The mount point will be created if it does not
#                  already exist.
#
#   min_gb      => only mount a volume if is at least as large as min_gb 
#   max_gb      => only mount a volume if is no larger than max_gb 
#
define cinderutils::ensure(
    Stdlib::Unixpath $mount_point = '/srv',
    Integer          $min_gb      = 10,
    Integer          $max_gb      = 1000,
){
    if has_key($facts['mountpoints'], $mount_point) {
        if $facts['mountpoints'][$mount_point]['size_bytes'] < $min_gb * 1024 * 1024 * 1024 {
            fail("Volume at ${mount_point} is smaller than required size of ${min_gb}GB")
        }

        # find the volume info for this so we can use the uuid for mounting
        $cinder_vol = $facts['cinder_volumes'].reduce() |$memo, $volume| {
            $volume['mountpoint'] == $mount_point ? {
                true    => $volume,
                default => $memo
            }
        }
        $require_list = []
    } else {
        # find the first available volume of adequate size
        $cinder_vol = $facts['cinder_volumes'].reduce(undef) |$memo, $volume| {
            if (!$memo and
                $volume['mountpoint'] == '' and
                $volume['size'] >= $min_gb * 1024 * 1024 * 1024 and
                $volume['size'] <= $max_gb * 1024 * 1024 * 1024) {
                exec { "prepare_cinder_volume_${mount_point}":
                    command => "/usr/sbin/prepare_cinder_volume --force --device ${volume['dev']} --mountpoint ${mount_point}",
                    require => File['/usr/sbin/prepare_cinder_volume'],
                    user    => 'root',
                }
                $require_list = Exec["prepare_cinder_volume_${mount_point}"]
                $volume
            } else {
                $memo
            }
        }
        if $cinder_vol == undef {
            fail("No mount at ${mount_point} and no volumes are available to mount.\n\nTo proceed, create and attach a Cinder volume of at least size ${min_gb}GB.")
        }
    }

    mount { $mount_point:
        ensure  => mounted,
        atboot  => true,
        device  => "UUID=${cinder_vol['uuid']}",
        options => 'discard,nofail,x-systemd.device-timeout=2s',
        require => $require_list,
    }
}
