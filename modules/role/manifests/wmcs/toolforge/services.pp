class role::wmcs::toolforge::services {
    system::role { $name: }

    include profile::toolforge::base
    include profile::toolforge::apt_pinning
    include profile::toolforge::services::aptly
}
