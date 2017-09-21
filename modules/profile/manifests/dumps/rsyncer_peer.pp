class profile::dumps::rsyncer_peer {
    class {'::dumps::rsync::default':}
    class {'::dumps::rsync::memfix':}
    class {'::dumps::rsync::peers':}
}
