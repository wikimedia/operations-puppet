# filtertags: labs-project-quarry
class role::labs::quarry::database {
    include role::labs::lvm::srv

    class { '::quarry::database':
        require => Mount['/srv']
    }
}
