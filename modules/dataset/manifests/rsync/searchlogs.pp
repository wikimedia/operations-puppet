class dataset::rsync::searchlogs($enable=true) {
    if ($enable) {
        $ensure = 'present'
    }
    else {
        $ensure = 'absent'
    }

    system::role { 'dataset::rsync::searchlogs':
        ensure      => $ensure,
        description => 'mirror of search logs'
    }

    include role::mirror::common
    include dataset::rsync::common
    file { '/etc/rsyncd.d/40-rsync-searchlogs.conf':
        ensure  => $ensure,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        source  => 'puppet:///dataset/rsync/rsyncd.conf.searchlogs',
        notify  => Exec['update-rsyncd.conf'],
    }
}
