class role::labs::quarry::web {
    include role::labs::lvm::srv
    include ::labsdebrepo

    class { '::quarry::web':
        require => [Mount['/srv'], Class['::labsdebrepo']],
    }
}

class role::labs::quarry::celeryrunner {
    include role::labs::lvm::srv
    include ::labsdebrepo

    class { '::quarry::celeryrunner':
        require => [Mount['/srv'], Class['::labsdebrepo']],
    }
}

class role::labs::quarry::database {
    include role::labs::lvm::srv

    class { '::quarry::database':
        require => Mount['/srv']
    }
}

class role::labs::quarry::redis {
    include role::labs::lvm::srv

    class { '::quarry::redis':
        require => Mount['/srv']
    }
}
