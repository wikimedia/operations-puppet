# filtertags: labs-project-deployment-prep
class role::cache::text {

    system::role { 'cache::text':
        description => 'text Varnish cache server',
    }
    include ::standard
    include ::profile::cache::base
    include ::profile::cache::ssl::unified
    include ::profile::cache::text
    include ::role::ipsec
}
