class role::wmcs::toolforge::checker {
    system::role { $name:
        description => 'Toolforge checker'
    }

    include profile::toolforge::base
    include profile::toolforge::checker
}
