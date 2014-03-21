# Allocate all of the instance's extra space as /srv
class role::labs::lvm::srv {
    include labs_lvm
    labs_lvm::volume { 'second-local-disk': mountat => '/srv' }
}
