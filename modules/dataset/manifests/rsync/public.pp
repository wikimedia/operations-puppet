class dataset::rsync::public($enable=true) {
    if ($enable) {
        $ensure = 'present'
    }
    else {
        $ensure = 'absent'
    }

    system::role { 'dataset::rsync::public':
        ensure      => $ensure,
        description => 'rsyncer to the public of dumps'
    }

    include role::mirror::common
    include dataset::rsync::common
    file { '/etc/rsyncd.d/20-rsync-dumps_to_public.conf':
        ensure  => $ensure,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        source  => 'puppet:///dataset/rsync/rsyncd.conf.dumps_to_public',
        notify  => Exec['update-rsyncd.conf'],
    }
}
