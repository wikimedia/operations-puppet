class dataset::rsync::peers($enable=true) {
    if ($enable) {
        $ensure = 'present'
    }
    else {
        $ensure = 'absent'
    }

    system::role { 'dataset::rsync::peers':
        ensure      => $ensure,
        description => 'rsyncer to internal peers of dumps'
    }

    include role::mirror::common

    include dataset::rsync::common
    file { '/etc/rsyncd.d/10-rsync-datasets_to_peers.conf':
        ensure  => $ensure,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        source  => 'puppet:///dataset/rsync/rsyncd.conf.datasets_to_peers',
        notify  => Exec['update-rsyncd.conf'],
    }
}
