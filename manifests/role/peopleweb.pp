class role::peopleweb {

    include standard

    class { '::publichtml':
        sitename     => 'people.wikimedia.org',
        server_admin => 'noc@wikimedia.org',
    }
}
