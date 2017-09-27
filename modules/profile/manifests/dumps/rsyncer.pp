class profile::dumps::rsyncer(
    $rsync_clients = hiera('dumps_web_rsync_server_clients'),
) {
    class {'::dumps::rsync::default':}
    class {'::dumps::rsync::media':}
    class {'::dumps::rsync::memfix':}
    class {'::dumps::rsync::pagecounts_ez':}
    class {'::dumps::rsync::peers':}
    class {'::dumps::rsync::phab_dump':}
    $hosts_allow = join(concat($rsync_clients['ipv4'], $rsync_clients['ipv6']), ' ')
    class {'::dumps::rsync::public': hosts_allow => $hosts_allow,}
}
