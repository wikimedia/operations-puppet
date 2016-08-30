class role::archiva::migration {

    $sourceip='208.80.154.154'

    ferm::service { 'archiva-migration-rsync':
        proto  => 'tcp',
        port   => '873',
        srange => "${sourceip}/32",
    }

    include rsync::server

    rsync::server::module { 'archiva':
        path        => '/var/lib/archiva',
        read_only   => 'no',
        hosts_allow => $sourceip,
    }

}
