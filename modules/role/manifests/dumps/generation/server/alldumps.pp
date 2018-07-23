class role::dumps::generation::server::alldumps {
    system::role { 'dumps::generation::server::alldumps': description => 'NFS server of xml/sql and misc dumps generation filesystem to dumps producer hosts' }

    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::dumps::generation::server::alldumps
    include ::profile::dumps::nfs
    include ::profile::dumps::generation::server::rsync_firewall
    include ::profile::dumps::rsyncer_peer
    include ::profile::dumps::generation::server::cleanup
    include ::profile::dumps::generation::server::jobswatcher
    include ::profile::dumps::generation::server::exceptionchecker
}
