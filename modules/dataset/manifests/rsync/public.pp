class dataset::rsync::public($enable=true) {
    if ($enable) {
        $ensure = 'present'
    }
    else {
        $ensure = 'absent'
    }

    include ::dataset::common
    include ::dataset::rsync::common
    file { '/etc/rsyncd.d/20-rsync-dumps_to_public.conf':
        ensure => $ensure,
        mode   => '0444',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/dataset/rsync/rsyncd.conf.dumps_to_public',
        notify => Exec['update-rsyncd.conf'],
    }
}
