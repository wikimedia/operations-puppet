#
# This is just for testing new things
# and will go away
#

class role::labs::instancetest {

    class { '::labs_lvm':
        device => '/dev/vda'
    }

    labs_lvm::volume { 'store':
        mountpoint => '/mnt'
    }

}

