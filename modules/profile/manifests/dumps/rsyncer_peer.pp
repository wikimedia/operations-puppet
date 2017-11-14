class profile::dumps::rsyncer_peer(
    $user = hiera('profile::dumps::rsyncer_peer::dumps_user'),
    $group = hiera('profile::dumps::rsyncer_peer::dumps_group'),
    $mntpoint = hiera('profile::dumps::rsyncer_peer::dumps_mntpoint'),
) {
    $peer_hosts = 'dataset1001.wikimedia.org ms1001.wikimedia.org dumpsdata1001.eqiad.wmnet dumpsdata1002.eqiad.wmnet labstore1006.wikimedia.org'

    class {'::dumps::rsync::common':
        user  => $user,
        group => $group,
    }
    class {'::dumps::rsync::default':}
    class {'::dumps::rsync::memfix':}
    class {'::dumps::rsync::peers':
        hosts_allow => $peer_hosts,
        datapath    => $mntpoint,
    }
}
