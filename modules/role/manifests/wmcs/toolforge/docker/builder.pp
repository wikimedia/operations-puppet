class role::wmcs::toolforge::docker::builder(
) {
    system::role { $name: }

    include profile::toolforge::base
    include profile::toolforge::apt_pinning
    include profile::toolforge::docker::builder
}
