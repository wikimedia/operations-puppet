class profile::dumps::rsyncer_peer {
    class {'::dumps::rsync::common':
        user  => 'datasets',
        group => 'datasets',
    }
    $peer_hosts = 'dataset1001.wikimedia.org ms1001.wikimedia.org dumpsdata1001.eqiad.wmnet dumpsdata1002.eqiad.wmnet'
    class {'::dumps::rsync::default':}
    class {'::dumps::rsync::memfix':}
    class {'::dumps::rsync::peers': hosts_allow => $peer_hosts}
}
