class profile::wmcs::nfs::rsync_peer(
    String $user = lookup('profile::wmcs::nfs::rsync::user'),
    String $group = lookup('profile::wmcs::nfs::rsync::group'),
    String $datapath = lookup('profile::wmcs::nfs::rsync::datapath'),
    Stdlib::Host $primary_host = lookup('scratch_active_server')
) {

    class {'::labstore::rsync::syncserver':
        user         => $user,
        group        => $group,
        primary_host => $primary_host,
    }
    class {'::vm::higher_min_free_kbytes':}

}