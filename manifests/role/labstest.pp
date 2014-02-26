#
# This is just for testing new things
# and will go away
#

class role::labs::instancetest {

    class { '::labs_lvm':
        disk => '/dev/vda'
    }

    labs_lvm::volume { 'store':
        mountat => '/mnt'
    }

}

