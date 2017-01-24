class role::gerrit::migration {

    $sourceip='208.80.154.82'

    ferm::service { 'gerrit-migration-rsync':
        proto  => 'tcp',
        port   => '873',
        srange => "${sourceip}/32",
    }

    include rsync::server

    rsync::server::module { 'srv-gerrit':
        path        => '/srv/gerrit',
        read_only   => 'no',
        hosts_allow => $sourceip,
    }

}
