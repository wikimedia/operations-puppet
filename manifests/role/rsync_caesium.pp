class role::rsync_caesium {

    $sourceip='10.64.32.145'

    include rsync::server

    rsync::server::module { 'releases':
        path        => '/srv/org/wikimedia',
        read_only   => 'no',
        hosts_allow => $sourceip,
    }

}
