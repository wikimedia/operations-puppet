# == Class role::swap
# Installs a jupyterhub instance with analytics cluster access
#
# https://wikitech.wikimedia.org/wiki/SWAP
#
class role::swap {
    system::role { 'SWAP (Jupyter Notebook)': }
    include ::standard
    include ::profile::analytics::cluster::gitconfig
    include ::profile::swap
    include ::profile::analytics::cluster::packages::hadoop
    include ::profile::analytics::cluster::packages::statistics
    require ::profile::analytics::cluster::repositories::statistics
    include ::profile::analytics::cluster::client

    # Include analytics/refinery deployment target.
    include ::profile::analytics::refinery

    # This is a Hadoop client, and should
    # have any special analytics system users on it
    # for interacting with HDFS.
    include ::profile::analytics::cluster::users
}
