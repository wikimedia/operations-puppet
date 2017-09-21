class dataset::rsync::public($enable=true) {
    if ($enable) {
        $ensure = 'present'
    }
    else {
        $ensure = 'absent'
    }

    $hosts_allow = 'sagres.c3sl.ufpr.br odysseus.fi.muni.cz odysseus.linux.cz odysseus.ip6.fi.muni.cz poincare.acc.umu.se wikimedia.bytemark.co.uk'

    include ::dataset::common
    include ::dataset::rsync::common
    file { '/etc/rsyncd.d/20-rsync-dumps_to_public.conf':
        ensure  => $ensure,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('dataset/rsync/rsyncd.conf.dumps_to_public'),
        notify  => Exec['update-rsyncd.conf'],
    }
}
