class role::wmcs::toolforge::proxy {
    include profile::toolforge::base
    include profile::toolforge::infrastructure
    include profile::toolforge::proxy
    include profile::toolforge::toolviews
    include profile::firewall
}
