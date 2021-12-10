# filtertags: labs-project-deployment-prep
class role::cache::upload_envoy {
    system::role { 'cache::upload_envoy':
        description => 'upload Envoy/Varnish/ATS cache server',
    }

    include ::profile::base::production
    include ::profile::netconsole::client

    include ::profile::cache::base
    include ::profile::cache::envoy
    include ::profile::cache::varnish::frontend
    include ::profile::prometheus::varnish_exporter
    include ::profile::trafficserver::backend
}
