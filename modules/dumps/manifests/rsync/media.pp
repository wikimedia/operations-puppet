class dumps::rsync::media(
    $hosts_allow = undef,
    $user = undef,
    $deploygroup = undef,
    $miscdatasetsdir = undef,
) {
    file { '/etc/rsyncd.d/30-rsync-media.conf':
        ensure  => 'present',
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('dumps/rsync/rsyncd.conf.media.erb'),
        notify  => Exec['update-rsyncd.conf'],
    }
}
