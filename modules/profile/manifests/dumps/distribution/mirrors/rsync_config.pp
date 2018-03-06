class profile::dumps::distribution::mirrors::rsync_config(
    $rsync_clients = hiera('dumps_web_rsync_server_clients'),
    $rsyncer_settings = hiera('profile::dumps::rsyncer'),
    $xmldumpsdir = hiera('profile::dumps::distribution::xmldumpsdir'),
    $miscdatasetsdir = hiera('profile::dumps::distribution::miscdumpsdir'),
) {
    $hosts_allow = join(concat($rsync_clients['ipv4']['external'], $rsync_clients['ipv6']['external']), ' ')

    class {'::dumps::rsync::public':
        hosts_allow     => $hosts_allow,
        xmldumpsdir     => $xmldumpsdir,
        miscdatasetsdir => $miscdatasetsdir,
    }
}
