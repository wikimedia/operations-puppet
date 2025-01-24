class role::swift::proxy {
    include profile::base::production
    include profile::firewall
    include profile::prometheus::memcached_exporter
    include profile::lvs::realserver
    include profile::swift::proxy
}
