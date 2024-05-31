class role::wmcs::toolforge::services {
    include profile::toolforge::base
    include profile::toolforge::apt_pinning
    include profile::toolforge::services::aptly
}
