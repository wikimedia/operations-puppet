# == Define: cassandra::jbod_device
#
# Configure a block device to be used for Cassandra JBOD.
# Specifically, create the desired mount point directory and add an entry to
# /etc/fstab.
#
# === Parameters
#
# [*mount_point*]
#   The mount point to use
#
# [*mount_options*]
#   What options to use for /etc/fstab

define cassandra::jbod_device (
  $mount_point = "/srv/${title}",
  $mount_options = 'nofail,defaults',
) {
    $device = $title

    file { "mountpoint-${mount_point}":
        ensure => directory,
        path   => $mount_point,
        owner  => 'root',
        group  => 'root',
        mode   => '0750',
        before => Mount[$mount_point],
    }

    mount { $mount_point:
        ensure   => mounted,
        device   => "/dev/${device}",
        name     => $mount_point,
        fstype   => 'ext4',
        options  => $mount_options,
        atboot   => true,
        remounts => true,
    }
}
