class role::rsync_ruthenium {

    $sourceip='10.64.32.146'

    include rsync::server

    rsync::server::module { 'ruthenium':
        path        => '/mnt/data',
        read_only   => 'no',
        hosts_allow => $sourceip,
    }

}
