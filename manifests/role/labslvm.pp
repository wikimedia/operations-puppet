# Allocate all of the instance's extra space as /mnt or the user specified
# mount point given in the $::lvm_mount_point global variable.
# FIXME: Deprecate and kill with mild fire
class role::labs::lvm::mnt {
    $mount_point = $::lvm_mount_point ? {
        undef   => '/mnt',
        default => $::lvm_mount_point,
    }
    labs_lvm::volume { 'second-local-disk': mountat => $mount_point }
}

# Allocate all of the instance's extra space as /srv
class role::labs::lvm::srv {
    labs_lvm::volume { 'second-local-disk': mountat => '/srv' }
}

# Allocate a custom LVM volume
class role::labs::lvm::volume(
    $mountat = '/srv',
    $size = '100%FREE',
) {
    labs_lvm::volume { 'second-local-disk':
        mountat => $mountat,
        size    => $size,
    }
}
