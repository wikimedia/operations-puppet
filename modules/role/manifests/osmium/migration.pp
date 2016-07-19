class role::osmium::migration {

    $sourceip='10.64.32.146'

    ferm::service { 'osmium-migration-rysnc':
        proto  => 'tcp',
        port   => '873',
        srange => "${sourceip}/32",
    }

    include rsync::server

    rsync::server::module { 'osmium-home':
        path        => '/srv/osmium',
        read_only   => 'no',
        hosts_allow => $sourceip,
    }

}
