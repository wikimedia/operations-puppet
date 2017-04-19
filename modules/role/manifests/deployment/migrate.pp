class role::deployment::migrate {

    $sourceip='10.192.16.132'

    ferm::service { 'deployment-migration-rsync':
        proto  => 'tcp',
        port   => '873',
        srange => "${sourceip}/32",
    }

    include rsync::server

    rsync::server::module { 'deployment-home':
        path        => '/home',
        read_only   => 'no',
        hosts_allow => $sourceip,
    }

}
