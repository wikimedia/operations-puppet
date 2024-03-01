class role::dumps::distribution::server {
    system::role { 'dumps::distribution::server': description => 'labstore host in the public VLAN that distributes Dumps to clients via NFS/Web/Rsync' }

    include profile::base::production
    include profile::firewall
    include profile::nginx

    include profile::dumps::distribution::server
    include profile::dumps::distribution::nfs
    include profile::dumps::distribution::rsync
    include profile::dumps::distribution::ferm
    include profile::dumps::distribution::web
    include profile::dumps::distribution::monitoring

    include profile::dumps::distribution::datasets::cleanup
    include profile::dumps::distribution::datasets::dumpstatusfiles_sync
    include profile::dumps::distribution::datasets::rsync_config
    include profile::dumps::distribution::datasets::fetcher

    include profile::dumps::distribution::mirrors::rsync_config

    # For downloading public datasets from HDFS analytics-hadoop.
    include profile::analytics::cluster::hdfs_mount

    # Install java, hadoop configuration and kerberos client and keytabs
    # for hdfs_tools to function (needed to pull data from HDFS)
    include profile::java
    include profile::hadoop::common
    include profile::kerberos::client
    include profile::kerberos::keytabs

    # Kerberos client and credentials to fetch data from
    # the Analytics Hadoop cluster.
    include profile::kerberos::client
    include profile::kerberos::keytabs

}
