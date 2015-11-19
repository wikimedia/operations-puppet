# Allocate all of the instance's extra space as /srv
class role::labs::lvm::srv {
    labs_lvm::volume { 'second-local-disk': 
        mountat => '/srv',
    }
}
