# filtertags: labs-project-quarry
class role::labs::quarry::redis {
    include role::labs::lvm::srv

    class { '::quarry::redis':
        require => Mount['/srv']
    }
}
