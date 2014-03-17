class dataset::rsync::pagecounts($enable=true) {
    if ($enable) {
        $ensure = 'present'
    }
    else {
        $ensure = 'absent'
    }

    system::role { 'dataset::rsync::pagecounts':
        ensure      => $ensure,
        description => 'mirror of pagecount stats'
    }

    include role::mirror::common
    include dataset::rsync::common

    file { '/etc/rsyncd.d/30-rsync-pagecounts.conf':
        ensure  => $ensure,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        source  => 'puppet:///modules/dataset/rsync/rsyncd.conf.pagecounts',
        notify  => Exec['update-rsyncd.conf'],
    }
}
