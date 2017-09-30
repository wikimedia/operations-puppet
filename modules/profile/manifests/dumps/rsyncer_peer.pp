class profile::dumps::rsyncer_peer {
    $peer_hosts = 'dataset1001.wikimedia.org ms1001.wikimedia.org'
    class {'::dumps::rsync::default':}
    class {'::dumps::rsync::memfix':}
    class {'::dumps::rsync::peers': hosts_allow => $peer_hosts}
}
