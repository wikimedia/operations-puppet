class role::swift::proxy {

    system::role { 'swift::proxy':
        description => 'swift frontend proxy',
    }

    include ::profile::base::production
    include ::profile::base::firewall
    include ::profile::conftool::client
    include ::profile::prometheus::memcached_exporter
    include ::profile::swift::proxy

}
