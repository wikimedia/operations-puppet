class role::analytics_cluster::webserver {

    system::role { 'analytics_cluster::webserver':
        description => 'Webserver hosting the main Analytics websites'
    }

    include ::profile::analytics::httpd
    include ::profile::analytics::cluster::gitconfig

    include ::profile::tlsproxy::envoy

    include ::profile::statistics::web

    include ::profile::base::firewall
    include ::profile::base::production

    # Install java, hadoop configuration and kerberos client and keytabs
    # for hdfs_tools to function (needed to pull data from HDFS)
    include profile::java
    include profile::hadoop::common
    include profile::kerberos::client
    include profile::kerberos::keytabs
}
