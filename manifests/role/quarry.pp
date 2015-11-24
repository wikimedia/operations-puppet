class role::quarry::web {
    include ::labs_debrepo

    requires_realm('labs')

    class { '::quarry::web':
        require => Class['::labs_debrepo'],
    }
}

class role::quarry::celeryrunner {
    include ::labs_debrepo

    requires_realm('labs')

    class { '::quarry::celeryrunner':
        require => Class['::labs_debrepo'],
    }
}

class role::quarry::database {

    requires_realm('labs')

    class { '::quarry::database':
    }
}

class role::quarry::redis {
    include role::labs::lvm::srv

    requires_realm('labs')

    class { '::quarry::redis':
        require => Mount['/srv']
    }
}

# Should be included on an instance that already has
# a Quarry install (celery or web) setup
class role::quarry::killer {
    include quarry::querykiller
}
