# filtertags: labs-project-deployment-prep
class role::cache::upload_haproxy {
    system::role { 'cache::upload_haproxy':
        description => 'upload HAProxy/Varnish/ATS cache server',
    }

    include ::profile::standard
    include ::profile::netconsole::client

    include ::profile::cache::base
    include ::profile::cache::haproxy
    include ::profile::cache::varnish::frontend
    include ::profile::prometheus::varnish_exporter
    include ::profile::trafficserver::backend
}
