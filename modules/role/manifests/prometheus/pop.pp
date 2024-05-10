class role::prometheus::pop {
    include profile::base::production
    include profile::firewall

    require profile::prometheus::ops

    include profile::alerts::deploy::prometheus

    include profile::prometheus::rsyncd
    include profile::prometheus::web

    include profile::prometheus::web_idp

    include profile::prometheus::migration
}
