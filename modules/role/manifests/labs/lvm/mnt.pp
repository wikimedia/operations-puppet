# Allocate all of the instance's extra space as /mnt or the user specified
# mount point given in the $::lvm_mount_point global variable.
# FIXME: Deprecate and kill with mild fire
#
class role::labs::lvm::mnt($mount_point = $::lvm_mount_point) {
    $mount = $mount_point ? {
        undef   => '/mnt',
        default => $mount_point,
    }
    labs_lvm::volume { 'second-local-disk': mountat => $mount }
}
