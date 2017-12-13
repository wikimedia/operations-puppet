class dumps::rsync::pagecounts_ez(
    $hosts_allow = undef,
    $user = undef,
    $deploygroup = undef,
    $miscdatasetsdir = undef,
) {
    file { '/etc/rsyncd.d/30-rsync-pagecounts_ez.conf':
        ensure  => 'present',
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('dumps/rsync/rsyncd.conf.pagecounts_ez.erb'),
        notify  => Exec['update-rsyncd.conf'],
    }
}
