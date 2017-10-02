class profile::dumps::rsyncer(
    $rsync_clients = hiera('dumps_web_rsync_server_clients'),
) {
    $stats_hosts = 'stat1005.eqiad.wmnet stat1006.eqiad.wmnet'
    $peer_hosts = 'dataset1001.wikimedia.org ms1001.wikimedia.org'
    $phab_hosts = 'phab1001.eqiad.wmnet'
    $mwlogs_hosts = 'mwlog1001.eqiad.wmnet 2620:0:861:103:1618:77ff:fe33:4ac0 mwlog2001.codfw.wmnet 2620:0:860:103:1618:77ff:fe4e:3159'
    class {'::dumps::rsync::default':}
    class {'::dumps::rsync::media': hosts_allow => $stats_hosts}
    class {'::dumps::rsync::memfix':}
    class {'::dumps::rsync::pagecounts_ez': hosts_allow => $stats_hosts}
    class {'::dumps::rsync::peers': hosts_allow => $peer_hosts}
    class {'::dumps::rsync::phab_dump': hosts_allow => $phab_hosts}
    $hosts_allow = join(concat($rsync_clients['ipv4']['external'], $rsync_clients['ipv6']['external']), ' ')
    class {'::dumps::rsync::public': hosts_allow => $hosts_allow,}
    class {'::dumps::rsync::slowparse_logs': hosts_allow => $mwlog_hosts}
}
