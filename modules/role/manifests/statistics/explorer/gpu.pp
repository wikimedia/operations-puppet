class role::statistics::explorer::gpu {
    system::role { 'statistics::explorer::gpu':
        description => 'Statistics & Analytics cluster explorer (private data access) with GPU (for local computations)'
    }
    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::statistics::gpu
    include ::profile::statistics::explorer
    include ::profile::analytics::cluster::client
    # This is a Hadoop client, and should
    # have any special analytics system users on it
    # for interacting with HDFS.
    include ::profile::analytics::cluster::users
    include ::profile::analytics::refinery
    include ::profile::analytics::cluster::packages::hadoop

    include ::profile::kerberos::client
    include ::profile::kerberos::keytabs
}
