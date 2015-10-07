# == Class: role::labs::wdq_mm
# Role class for setting up an instance of
# Magnus' WDQ on labs
class role::labs::wdq_mm {
    include misc::labsdebrepo

    include labs_lvm
    labs_lvm::volume { 'instance-storage':
        mountat => '/srv',
        size    => '80%FREE',
    }

    class { '::wdq_mm':
        require => [
            Class['misc::labsdebrepo'],
            Labs_lvm::Volume['instance-storage'],
        ]
    }
}

# == Class: role::labs::wdq_mm::lb
# Load balancer for balancing across multiple instances
# of role::labs::wdq_mm
class role::labs::wdq_mm::lb {
    class { '::wdq_mm::lb':
    }
}
