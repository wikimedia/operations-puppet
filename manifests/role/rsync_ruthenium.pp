class role::rsync_ruthenium {

    $sourceip='10.64.16.151'

    include rsync::server

    rsync::server::module { 'ruthenium':
        path        => '/srv/ruthenium',
        read_only   => 'no',
        hosts_allow => $sourceip,
    }

}
