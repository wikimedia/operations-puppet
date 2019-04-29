# filtertags: labs-project-deployment-prep
class role::cache::upload_ats {
    system::role { 'cache::upload_ats':
        description => 'upload Varnish/ATS cache server',
    }

    include ::profile::standard

    include ::profile::cache::base
    include ::profile::cache::ssl::unified
    include ::profile::cache::varnish::frontend
    include ::profile::trafficserver::backend
}
