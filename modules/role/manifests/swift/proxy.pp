# filtertags: labs-project-deployment-prep labs-project-swift
class role::swift::proxy {

    system::role { 'swift::proxy':
        description => 'swift frontend proxy',
    }

    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::conftool::client
    include ::profile::prometheus::memcached_exporter
    include ::profile::swift::proxy

}
