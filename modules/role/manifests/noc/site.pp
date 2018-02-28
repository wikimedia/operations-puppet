# https://noc.wikimedia.org/
class role::noc::site {

    system::role { 'noc::site': description => 'noc.wikimedia.org' }

    ferm::service { 'noc-http':
        proto  => 'tcp',
        port   => 'http',
        srange => '$CACHE_MISC',
    }

    include ::noc

    class { '::hhvm::admin': }
}

