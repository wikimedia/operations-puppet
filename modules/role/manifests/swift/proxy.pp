class role::swift::proxy {

    system::role { 'swift::proxy':
        description => 'Swift frontend (ms cluster)',
    }

    include ::profile::base::production
    include ::profile::firewall
    include ::profile::conftool::client
    include ::profile::prometheus::memcached_exporter
    include ::profile::swift::proxy

}
