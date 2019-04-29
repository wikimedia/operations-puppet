class profile::wmcs::nfs::rsync(
    String $user = lookup('profile::wmcs::nfs::rsync::user'),
    String $group = lookup('profile::wmcs::nfs::rsync::group'),
    String $datapath = lookup('profile::wmcs::nfs::rsync::datapath'),
    Stdlib::Host $primary_host = lookup('scratch_active_server')
) {

    # $service_running = $facts['fqdn']? {
    #     $primary_host => true,
    #     default       => false,
    # }
    class {'::labstore::rsync::syncserver':
        user         => $user,
        group        => $group,
        primary_host => $primary_host,
        is_active    => false,
    }

    # This may not be needed
    # class {'::vm::higher_min_free_kbytes':}

}