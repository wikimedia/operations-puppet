# sets up a redis server for quarry
class role::quarry::redis {
    include role::labs::lvm::srv

    requires_realm('labs')

    class { '::quarry::redis':
        require => Mount['/srv']
    }
}

