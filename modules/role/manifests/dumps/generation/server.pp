class role::dumps::generation::server {
    system::role { 'dumps::generation::server': description => 'NFS server of dumps generation filesystem to dumps producer hosts' }

    include ::standard
    include ::profile::dumps::generation::server
    include ::profile::dumps::nfs_server
}
