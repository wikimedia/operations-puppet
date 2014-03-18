# Allocate all of the instance's extra space as /mnt
class role::labs::lvm::mnt {
    include labs_lvm
    labs_lvm::volume { 'second-local-disk': mountat => '/mnt' }
}
