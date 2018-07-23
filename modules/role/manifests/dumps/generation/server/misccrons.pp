class role::dumps::generation::server::misccrons {
    system::role { 'dumps::generation::server::misccrons': description => 'NFS server of misc dump crons generation filesystem to dumps producer hosts' }

    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::dumps::generation::server::misccrons
    include ::profile::dumps::nfs
    include ::profile::dumps::generation::server::rsync_firewall
    include ::profile::dumps::rsyncer_peer
    include ::profile::dumps::generation::server::cleanup
}
