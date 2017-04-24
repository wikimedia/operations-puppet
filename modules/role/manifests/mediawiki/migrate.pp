class role::mediawiki::migrate {

    $sourceip='10.64.32.13'

    ferm::service { 'mw-maintenance-migration-rsync':
        proto  => 'tcp',
        port   => '873',
        srange => "${sourceip}/32",
    }

    include rsync::server
    rsync::server::module { 'terbium-home':
        path        => '/srv/terbium-home',
        read_only   => 'no',
        hosts_allow => $sourceip,
    }
}
