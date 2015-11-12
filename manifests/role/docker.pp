class role::docker::registry {
    require role::labs::lvm::srv

    class { '::docker::registry':
        datapath => '/srv/registry',
    }
}
