# filtertags: labs-project-deployment-prep
class role::cache::upload {
    system::role { 'cache::upload':
        description => 'upload Varnish/ATS cache server',
    }

    include ::profile::standard
    include ::profile::netconsole::client

    include ::profile::cache::base
    include ::profile::cache::varnish::frontend
    include ::profile::trafficserver::backend
    include ::profile::trafficserver::tls
}
