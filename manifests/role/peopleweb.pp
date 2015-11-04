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

class role::peopleweb::migration {

    $sourceip='10.64.32.13'

    ferm::service { 'peopleweb-migration-rysnc':
        proto  => 'tcp',
        port   => '873',
        srange => "${sourceip}/32",
    }

    include rsync::server

    rsync::server::module { 'people-homes':
        path        => '/home',
        read_only   => 'no',
        hosts_allow => $sourceip,
    }

}

