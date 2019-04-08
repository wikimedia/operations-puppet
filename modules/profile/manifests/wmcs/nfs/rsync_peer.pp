class profile::wmcs::nfs::rsync_peer(
    String $user = lookup('profile::wmcs::nfs::rsync::user'),
    String $group = lookup('profile::wmcs::nfs::rsync::group'),
    String $mntpoint = lookup('profile::wmcs::nfs::rsync::mntpoint'),
) {

    class {'::labstore::rsync::syncserver':
        user  => $user,
        group => $group,
    }
    class {'::vm::higher_min_free_kbytes':}

}