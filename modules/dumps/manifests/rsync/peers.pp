class dumps::rsync::peers {
    include ::dumps::rsync::common
    file { '/etc/rsyncd.d/10-rsync-datasets_to_peers.conf':
        ensure => 'present',
        mode   => '0444',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/dumps/rsync/rsyncd.conf.datasets_to_peers',
        notify => Exec['update-rsyncd.conf'],
    }
}
