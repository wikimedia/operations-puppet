class dataset::rsync::media($enable=true) {
    if ($enable) {
        $ensure = 'present'
    }
    else {
        $ensure = 'absent'
    }

    include ::dataset::common
    include ::dataset::rsync::common

    file { '/etc/rsyncd.d/30-rsync-media.conf':
        ensure => $ensure,
        mode   => '0444',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/dataset/rsync/rsyncd.conf.media',
        notify => Exec['update-rsyncd.conf'],
    }
}
