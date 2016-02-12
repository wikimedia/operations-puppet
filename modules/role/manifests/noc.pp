# https://noc.wikimedia.org/
class role::noc {

    system::role { 'role::noc': description => 'noc.wikimedia.org' }

    ferm::service { 'noc-http':
        proto   => 'tcp',
        port    => 'http',
    }

    include ::noc
}

