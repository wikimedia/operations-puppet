class dumps::rsync::media {
    include ::dumps::rsync::common

    file { '/etc/rsyncd.d/30-rsync-media.conf':
        ensure => 'present',
        mode   => '0444',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/dumps/rsync/rsyncd.conf.media',
        notify => Exec['update-rsyncd.conf'],
    }
}
