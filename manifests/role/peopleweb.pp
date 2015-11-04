class role::peopleweb {

    include standard

    class { '::publichtml':
        sitename     => 'people.wikimedia.org',
        server_admin => 'noc@wikimedia.org',
    }

    ferm::service { 'people-http':
        proto => 'tcp',
        port  => '80',
    }
}
