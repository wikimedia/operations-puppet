# filtertags: labs-project-deployment-prep
class role::cache::upload {
    system::role { 'cache::upload':
        description => 'upload Varnish cache server',
    }

    include ::standard

    include ::profile::cache::base
    include ::profile::cache::ssl::unified
    include ::profile::cache::upload
    include ::role::ipsec
}
