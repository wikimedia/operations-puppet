class role::dumps::generation::server::fallback {
    system::role { 'dumps::generation::server': description => 'Fallback NFS server of dumps generation filesystem to dumps producer hosts' }

    include ::standard
    include ::profile::dumps::generation::server::fallback
    include ::profile::dumps::generation::server::rsync
    include ::profile::dumps::nfs::generation
}
