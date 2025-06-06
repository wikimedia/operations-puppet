class role::prometheus::pop {


    include profile::base::production
    include profile::firewall

    include profile::prometheus::common

    if $facts['networking']['fqdn'] != 'prometheus7002.magru.wmnet' {
        require profile::prometheus::ops

        include profile::alerts::deploy::prometheus
    }

    include profile::prometheus::rsyncd
    include profile::prometheus::web

    include profile::prometheus::web_idp
}
