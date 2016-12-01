class role::phabricator::migration {

    $sourceip='208.80.154.82'

    ferm::service { 'phabricator-migration-rysnc':
        proto  => 'tcp',
        port   => '873',
        srange => "${sourceip}/32",
    }

    include rsync::server

    rsync::server::module { 'srv-phabricator':
        path        => '/srv/repos',
        read_only   => 'no',
        hosts_allow => $sourceip,
    }

}
