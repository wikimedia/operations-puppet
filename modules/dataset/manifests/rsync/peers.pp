class dataset::rsync::peers($enable=true) {
    if ($enable) {
        $ensure = 'present'
    }
    else {
        $ensure = 'absent'
    }

    include ::dataset::common

    include ::dataset::rsync::common
    file { '/etc/rsyncd.d/10-rsync-datasets_to_peers.conf':
        ensure => $ensure,
        mode   => '0444',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/dataset/rsync/rsyncd.conf.datasets_to_peers',
        notify => Exec['update-rsyncd.conf'],
    }
}
