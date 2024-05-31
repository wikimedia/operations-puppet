class role::wmcs::toolforge::package_builder {
    include profile::toolforge::apt_pinning
    include profile::toolforge::package_builder

    # arturo thinks we don't need this, trying in bullseye without it
    if debian::codename::lt('bullseye') {
        include profile::labs::lvm::srv
    }
}
