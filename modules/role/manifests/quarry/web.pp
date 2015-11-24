# sets up the webserver part of quarry
class role::quarry::web {
    include ::labs_debrepo

    requires_realm('labs')

    class { '::quarry::web':
        require => Class['::labs_debrepo'],
    }
}

