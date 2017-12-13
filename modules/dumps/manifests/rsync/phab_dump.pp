class dumps::rsync::phab_dump(
    $hosts_allow = undef,
    $miscdatasetsdir = undef,
) {
    file { '/etc/rsyncd.d/40-rsync-phab_dump.conf':
        ensure  => 'present',
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('dumps/rsync/rsyncd.conf.phab_dump.erb'),
        notify  => Exec['update-rsyncd.conf'],
    }
}
