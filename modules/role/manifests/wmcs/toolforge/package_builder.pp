class role::wmcs::toolforge::package_builder {
    system::role { $name:
        description => 'Debian package builder'
    }

    include ::profile::toolforge::apt_pinning
    include ::profile::labs::lvm::srv
    include ::profile::toolforge::package_builder
}
