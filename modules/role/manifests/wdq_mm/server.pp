# == Class: role::wdq_mm::server
# Role class for setting up an instance of
# Magnus' WDQ on labs
class role::wdq_mm::server {
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
        ],
    }
}
