class dumps::rsync::public(
    $hosts_allow = undef,
    $xmldumpsdir = undef,
    $miscdatasetsdir = undef,
)  {
    file { '/etc/rsyncd.d/20-rsync-dumps_to_public.conf':
        ensure  => 'present',
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('dumps/rsync/rsyncd.conf.dumps_to_public.erb'),
        notify  => Exec['update-rsyncd.conf'],
    }
}
