class dataset::rsync::phab_dump($enable=true) {
    if ($enable) {
        $ensure = 'present'
    }
    else {
        $ensure = 'absent'
    }

    include ::dataset::common

    include ::dataset::rsync::common
    file { '/etc/rsyncd.d/40-rsync-phab_dump.conf':
        ensure => $ensure,
        mode   => '0444',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/dataset/rsync/rsyncd.conf.phab_dump',
        notify => Exec['update-rsyncd.conf'],
    }
}
