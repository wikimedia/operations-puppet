# filtertags: labs-project-deployment-prep
class role::cache::upload {
    system::role { 'cache::upload':
        description => 'upload Varnish cache server',
    }

    include ::standard

    include ::profile::cache::base
    include ::profile::cache::ssl::unified
    include ::profile::cache::varnish::frontend
    include ::profile::cache::varnish::backend

    # TODO: refactor all this so that we have separate roles for production and labs
    if $::realm == 'production' {
        include ::role::ipsec
    }
}
