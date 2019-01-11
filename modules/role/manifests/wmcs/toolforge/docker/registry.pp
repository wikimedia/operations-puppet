class role::wmcs::toolforge::docker::registry(
) {
    system::role { $name: }

    include profile::labs::lvm::srv
    include profile::toolforge::base
    include profile::toolforge::apt_pinning
    include profile::toolforge::infrastructure
    include profile::toolforge::docker::registry
}
