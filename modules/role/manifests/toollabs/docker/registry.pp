class role::toollabs::docker::registry {
    include ::toollabs::infrastructure

    require role::labs::lvm::srv

    class { '::docker::registry':
        datapath => '/srv/registry',
    }
}
