class role::wmcs::toolforge::docker::registry(
) {
    system::role { $name: }

    include profile::toolforge::base
    include profile::toolforge::infrastructure
    include profile::toolforge::docker::registry
}
