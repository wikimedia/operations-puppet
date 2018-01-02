class role::cache::misc {
    system::role { 'cache::misc':
        description => 'misc Varnish cache server',
    }

    include ::profile::cache::base
    include ::profile::cache::ssl::unified
    include ::profile::cache::misc
    include ::role::ipsec
}
