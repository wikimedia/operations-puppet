class dumps::rsync::slowparse_logs(
    $hosts_allow = undef,
    $user = undef,
    $group = undef,
    $miscdatasetsdir = undef,
) {
    file { '/etc/rsyncd.d/10-rsync-slowparse-logs.conf':
        ensure  => 'present',
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('dumps/rsync/rsyncd.conf.slowparse_logs.erb'),
        notify  => Exec['update-rsyncd.conf'],
    }
}
