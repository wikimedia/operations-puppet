class role::dumps::generation::server::fallback {
    system::role { 'dumps::generation::server': description => 'Fallback NFS server of dumps generation filesystem to dumps producer hosts' }

    include ::standard
    include ::profile::base::firewall
    include ::profile::dumps::generation::server::common
    include ::profile::dumps::generation::server::rsync
    include ::profile::dumps::rsyncer_peer
    include ::profile::dumps::nfs
    include ::profile::dumps::web::dumpstatusfiles_sync
    include ::profile::dumps::web::cleanup
}
