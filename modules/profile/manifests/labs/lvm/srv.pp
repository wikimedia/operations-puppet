# Allocate all of the instance's extra space as /srv
#
# filtertags: labs-common
class profile::labs::lvm::srv {
    labs_lvm::volume { 'second-local-disk':
        mountat => '/srv',
    }
}
