class role::wmcs::toolforge::package_builder {
    include ::profile::toolforge::package_builder

    system::role { $name:
        description => 'Debian package builder'
    }
}
