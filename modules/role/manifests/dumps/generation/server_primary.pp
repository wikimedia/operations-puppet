class role::dumps::generation::server_primary {
    system::role { 'dumps::generation::server': description => 'Primary NFS server of dumps generation filesystem to dumps producer hosts' }

    include ::standard
    include ::profile::dumps::generation::server_primary
    include ::profile::dumps::nfs::generation
}
