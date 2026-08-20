class role::dumps::distribution::server {
    include profile::base::production
    include profile::firewall
    include profile::nginx

    include profile::dumps::distribution::server
    include profile::dumps::distribution::nfs
    include profile::dumps::distribution::rsync
    include profile::dumps::distribution::web

    include profile::lvs::realserver
    include profile::lvs::realserver::ipip

    include profile::dumps::distribution::datasets::cleanup
    include profile::dumps::distribution::datasets::rsync_config
    include profile::dumps::distribution::datasets::fetcher

    include profile::dumps::distribution::mirrors::rsync_config

    # Install java, hadoop configuration and kerberos client and keytabs
    # for hdfs_tools to function (needed to pull data from HDFS)
    include profile::java
    include profile::hadoop::common
    include profile::kerberos::client
    include profile::kerberos::keytabs
}
