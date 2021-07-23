# == Class role::statistics::explorer
# (stat1004)
# Access to analytics Hadoop cluster with private data.
# Not to be used for heavy local processing.
#
class role::statistics::explorer {
    system::role { 'statistics::explorer':
        description => 'Statistics & Analytics cluster explorer (private data access, no local compute)'
    }

    include ::profile::standard
    include ::profile::base::firewall

    include ::profile::java
    include ::profile::statistics::explorer
    include ::profile::analytics::cluster::client
    include ::profile::analytics::refinery
    include ::profile::analytics::cluster::packages::common

    include ::profile::analytics::client::limits
    include ::profile::kerberos::client
    include ::profile::kerberos::keytabs

    include ::profile::presto::client
    include ::profile::amd_gpu
    include ::profile::statistics::dataset_mount
    include ::profile::statistics::explorer::misc_jobs

    # Deploy wikimedia/discovery/analytics repository
    include ::profile::analytics::cluster::elasticsearch

    # Run anaconda-wmf based jupyterhub server.
    include ::profile::analytics::jupyterhub
}
