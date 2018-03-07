class profile::dumps::distribution::mirrors::rsync_config(
    $rsync_clients = hiera('dumps_web_rsync_server_clients'),
    $rsyncer_settings = hiera('profile::dumps::rsyncer'),
    $xmldumpsdir = hiera('profile::dumps::distribution::xmldumpspublicdir'),
    $miscdatasetsdir = hiera('profile::dumps::distribution::miscdumpsdir'),
) {
    $hosts_allow = join(concat($rsync_clients['ipv4']['external'], $rsync_clients['ipv6']['external']), ' ')

    file { '/etc/rsyncd.d/20-rsync-dumps_to_public.conf':
        ensure  => 'present',
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('profile/dumps/distribution/mirrors/rsyncd.conf.dumps_to_public.erb'),
        notify  => Exec['update-rsyncd.conf'],
    }
}
