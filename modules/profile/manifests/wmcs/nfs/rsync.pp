class profile::wmcs::nfs::rsync(
    String $user = lookup('profile::wmcs::nfs::rsync::user'),
    String $group = lookup('profile::wmcs::nfs::rsync::group'),
    String $datapath = lookup('profile::wmcs::nfs::rsync::datapath'),
    Stdlib::Host $primary_host = lookup('scratch_active_server'),
    Array[Stdlib::Host] $nfs_secondary_servers = lookup('secondary_nfs_servers'),
) {

    $secondary_host = join(delete($nfs_secondary_servers, $primary_host), '')
    $service_running = $facts['fqdn']? {
        $primary_host => true,
        default       => false,
    }
    class {'::labstore::rsync::syncserver':
        user         => $user,
        group        => $group,
        primary_host => $primary_host,
        partner_host => $secondary_host,
        is_active    => $service_running,
    }

    # This may not be needed
    # class {'::vm::higher_min_free_kbytes':}

}