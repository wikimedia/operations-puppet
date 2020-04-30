class role::statistics::private {
    system::role { 'statistics::private':
        description => 'Statistics private data host and general compute node'
    }

    include ::profile::standard
    include ::profile::base::firewall

    include ::profile::analytics::cluster::gitconfig

    include ::profile::statistics::private

    include ::profile::statistics::eventlogging_rsync

    include ::profile::statistics::dataset_mount
    include profile::analytics::geoip::archive

    # Include Hadoop and other analytics cluster
    # clients so that analysts can access Hadoop
    # from here.
    include ::profile::analytics::cluster::client

    include ::profile::analytics::cluster::packages::hadoop

    # Include analytics/refinery deployment target.
    include ::profile::analytics::refinery

    # This is a Hadoop client, and should
    # have any special analytics system users on it
    # for interacting with HDFS.
    include ::profile::analytics::cluster::users

    # Deploy wikimedia/discovery/analytics repository
    # to this node.
    include ::profile::analytics::cluster::elasticsearch

    # Deploy performance/asoranking repository
    # to this node.
    include ::profile::analytics::asoranking

    include ::profile::statistics::explorer::misc_jobs

    include ::profile::analytics::client::limits

    include ::profile::kerberos::client
    include ::profile::kerberos::keytabs

    include ::profile::presto::client
}
