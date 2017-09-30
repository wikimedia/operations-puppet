class profile::dumps::rsyncer(
    $rsync_clients = hiera('dumps_web_rsync_server_clients'),
) {
    $stats_hosts = 'stat1005.eqiad.wmnet stat1006.eqiad.wmnet'
    class {'::dumps::rsync::default':}
    class {'::dumps::rsync::media': hosts_allow => $stats_hosts}
    class {'::dumps::rsync::memfix':}
    class {'::dumps::rsync::pagecounts_ez': hosts_allow => $stats_hosts}
    class {'::dumps::rsync::peers':}
    class {'::dumps::rsync::phab_dump':}
    $hosts_allow = join(concat($rsync_clients['ipv4']['external'], $rsync_clients['ipv6']['external']), ' ')
    class {'::dumps::rsync::public': hosts_allow => $hosts_allow,}
}
