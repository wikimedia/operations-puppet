class role::wmcs::quarry::staging {
    system::role { $name:
        description => 'staging instance deployment for quarry'
    }

    include ::profile::quarry::database
    include ::profile::quarry::base
    include ::profile::quarry::staging_configure
    include ::profile::quarry::web
    include ::profile::quarry::celeryrunner
    include ::profile::quarry::redis
}
