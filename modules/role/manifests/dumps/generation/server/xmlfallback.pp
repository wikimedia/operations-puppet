class role::dumps::generation::server::xmlfallback {
    system::role { 'dumps::generation::server': description => 'Fallback NFS server of xml dumps generation filesystem to dumps producer hosts' }

    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::dumps::nfs
    include ::profile::dumps::generation::server::rsync_firewall
    include ::profile::dumps::rsyncer_peer
    include ::profile::dumps::generation::server::cleanup
    include ::profile::dumps::generation::server::dumpstatusfiles_sync
    include ::profile::dumps::generation::server::statsender
    include ::profile::dumps::generation::server::common
}