class profile::dumps::rsyncer {
    class {'::dumps::rsync::default':}
    class {'::dumps::rsync::media':}
    class {'::dumps::rsync::memfix':}
    class {'::dumps::rsync::pagecounts_ez':}
    class {'::dumps::rsync::peers':}
    class {'::dumps::rsync::phab_dump':}
    class {'::dumps::rsync::public':}
}
