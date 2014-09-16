# Allocate all of the instance's extra space as /srv
class role::labs::lvm::srv {
    include labs_lvm

    # Allow this to be configuable via a global
    # $::srv_logical_volume_size variable.
    # Default to using 100% of the vg space.
    $size = $::srv_logical_volume_size ? {
        undef   => '100%FREE',
        default => $::srv_logical_volume_size,
    }

    labs_lvm::volume { 'second-local-disk':
        mountat => '/srv',
        size    => $size,
    }
}
