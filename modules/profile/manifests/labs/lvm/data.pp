# Allocate all of the instance's extra space as /data
#
# filtertags: labs-common
class profile::labs::lvm::data {
    labs_lvm::volume { 'data-local-disk':
        mountat => '/data',
    }
}
