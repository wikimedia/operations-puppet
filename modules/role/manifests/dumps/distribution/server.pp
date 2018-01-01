class role::dumps::distribution::server {
    system::role { 'dumps::distribution::server': description => 'labstore host in the public VLAN that distributes Dumps to clients via NFS/Web/Rsync' }

    include ::standard
    include ::profile::base::firewall
    include ::profile::wmcs::nfs::ferm
    include ::profile::dumps::distribution::server
    include ::profile::dumps::distribution::nfs
    include ::profile::dumps::web::rsync_server
    include ::profile::dumps::rsyncer
    include ::profile::dumps::web::dumpstatusfiles_sync
    include ::profile::dumps::web::cleanup
    include ::profile::dumps::web::cleanup_miscdatasets
}
