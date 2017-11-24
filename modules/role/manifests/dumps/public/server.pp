class role::dumps::public::server {
    system::role { 'dumps::public::server': description => 'labstore host in the public VLAN that serves Dumps to clients via NFS/Web/Rsync' }

    include ::standard
    include ::profile::base::firewall
    include ::profile::wmcs::nfs::ferm
    include ::profile::dumps::public_server
    include ::profile::dumps::web::rsync_server
    include ::profile::dumps::rsyncer
    include ::profile::dumps::web::dumpstatusfiles_sync
    include ::profile::dumps::web::cleanup
}
