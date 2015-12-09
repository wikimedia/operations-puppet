# == Class: role::wdq_mm
# Role class for setting up an instance of
# Magnus' WDQ on labs
class role::wdq_mm {
    requires_realm('labs')

    include ::labs_debrepo

    include labs_lvm
    labs_lvm::volume { 'instance-storage':
        mountat => '/srv',
        size    => '80%FREE',
    }

    class { '::wdq_mm':
        require => [
            Class['::labs_debrepo'],
            Labs_lvm::Volume['instance-storage'],
        ]
    }
}

# == Class: role::wdq_mm::lb
# Load balancer for balancing across multiple instances
# of role::labs::wdq_mm
class role::wdq_mm::lb {
    requires_realm('labs')

    class { '::wdq_mm::lb':
    }
}
