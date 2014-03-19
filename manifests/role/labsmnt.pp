# Allocate all of the instance's extra space as /mnt or a user specified mount
# point.
class role::labs::lvm::mnt {
    include labs_lvm
    $mount_point = $::lvm_mount_point ? {
      undef   => '/mnt',
      default => $::lvm_mount_point,
    }
    labs_lvm::volume { 'second-local-disk': mountat => $mount_point }
}
