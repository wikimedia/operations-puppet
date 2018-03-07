# == Class role::swap
# Installs a jupyterhub instance with analytics cluster access
#
class role::swap {
    system::role { 'SWAP (Jupyter Notebook)': }
    include ::standard
    include ::profile::jupyterhub
    include ::role::analytics_cluster::client
}
