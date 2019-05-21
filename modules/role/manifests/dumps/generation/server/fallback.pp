class role::dumps::generation::server::fallback {
    system::role { 'dumps::generation::server': description => 'Fallback NFS server of dumps generation filesystem to dumps producer hosts' }

    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::base::firewall::log
    include ::profile::dumps::generation::server::common
    include ::profile::dumps::generation::server::rsync
    include ::profile::dumps::rsyncer_peer
    include ::profile::dumps::nfs
    include ::profile::dumps::generation::server::dumpstatusfiles_sync
    include ::profile::dumps::generation::server::cleanup
    include ::profile::dumps::generation::server::statsender
}
