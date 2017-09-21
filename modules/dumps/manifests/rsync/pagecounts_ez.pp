class dumps::rsync::pagecounts_ez {
    include ::dumps::rsync::common

    file { '/etc/rsyncd.d/30-rsync-pagecounts_ez.conf':
        ensure => 'present',
        mode   => '0444',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/dumps/rsync/rsyncd.conf.pagecounts_ez',
        notify => Exec['update-rsyncd.conf'],
    }
}
