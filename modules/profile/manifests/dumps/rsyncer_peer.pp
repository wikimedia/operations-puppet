class profile::dumps::rsyncer_peer(
    $rsyncer_settings = lookup('profile::dumps::rsyncer'),
) {
    $user = $rsyncer_settings['dumps_user']
    $group = $rsyncer_settings['dumps_group']
    $mntpoint = $rsyncer_settings['dumps_mntpoint']

    $peer_hosts = 'dumpsdata1001.eqiad.wmnet dumpsdata1002.eqiad.wmnet labstore1006.wikimedia.org labstore1007.wikimedia.org'

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
