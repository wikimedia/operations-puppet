class profile::dumps::rsyncer_peer(
    $rsyncer_settings = lookup('profile::dumps::rsyncer'),
    $peer_hosts = lookup('profile::dumps::peer_hosts'),
) {
    $user = $rsyncer_settings['dumps_user']
    $group = $rsyncer_settings['dumps_group']
    $mntpoint = $rsyncer_settings['dumps_mntpoint']

    class {'::dumps::rsync::common':
        user  => $user,
        group => $group,
    }
    class {'::dumps::rsync::default':}
    class {'::vm::higher_min_free_kbytes':}
    class {'::dumps::rsync::peers':
        hosts_allow => $peer_hosts,
        datapath    => $mntpoint,
    }
}
