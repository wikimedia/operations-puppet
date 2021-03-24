class role::wmcs::toolforge::docker::registry(
) {
    system::role { $name: }

    # we don't want this in buster, now using a cinder volume
    if debian::codename::eq('stretch') {
        include profile::labs::lvm::srv
    }
    include profile::toolforge::base
    include profile::toolforge::apt_pinning
    include profile::toolforge::infrastructure
    include profile::toolforge::docker::registry
}
