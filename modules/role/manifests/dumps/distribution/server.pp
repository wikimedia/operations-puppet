class role::dumps::distribution::server {
    system::role { 'dumps::distribution::server': description => 'labstore host in the public VLAN that distributes Dumps to clients via NFS/Web/Rsync' }

    include ::standard
    include ::profile::base::firewall
    include ::profile::wmcs::nfs::ferm

    include ::profile::dumps::distribution::server
    include ::profile::dumps::distribution::nfs
    include ::profile::dumps::distribution::rsync
    include ::profile::dumps::distribution::ferm
    include ::profile::dumps::distribution::web

    include ::profile::dumps::distribution::datasets::cleanup
    include ::profile::dumps::distribution::datasets::cleanup_miscdatasets
    include ::profile::dumps::distribution::datasets::dumpstatusfiles_sync
    include ::profile::dumps::distribution::datasets::rsync_config

    include ::profile::dumps::distribution::mirrors::rsync_config

}
