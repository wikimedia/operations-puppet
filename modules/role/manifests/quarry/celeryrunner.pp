# sets up celeryrunner for quarry
class role::quarry::celeryrunner {
    include ::labs_debrepo

    requires_realm('labs')

    class { '::quarry::celeryrunner':
        require => Class['::labs_debrepo'],
    }
}

