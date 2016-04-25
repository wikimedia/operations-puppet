# https://noc.wikimedia.org/
class role::noc::site {

    system::role { 'role::noc::site': description => 'noc.wikimedia.org' }

    ferm::service { 'noc-http':
        proto => 'tcp',
        port  => 'http',
    }

    include ::noc
}

