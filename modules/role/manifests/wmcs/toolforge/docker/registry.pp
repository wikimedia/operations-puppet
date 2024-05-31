class role::wmcs::toolforge::docker::registry(
) {
    include profile::toolforge::base
    include profile::toolforge::infrastructure
    include profile::toolforge::docker::registry
}
