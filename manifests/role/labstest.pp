#
# This is just for testing new things
# and will go away
#

class role::labs::instancetest {

    class { '::labs_lvm':
        device => '/dev/vda'
    }

    class { 'labs_lvm::volume':
        mountpoint => '/mnt'
    }

}

