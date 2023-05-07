class role::wmcs::toolserver_legacy {
    system::role { $name:
        description => 'Toolserver legacy server',
    }

    include ::profile::wmcs::toolserver_legacy
}
