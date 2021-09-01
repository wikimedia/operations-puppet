class role::labs::quarry::dbbackup {
    system::role { $name:
        description => 'database dump maintainer for quarry'
    }

    include profile::quarry::trove::backup
}
