# == Class role::swap
# Installs a jupyterhub instance with analytics cluster access
#
# https://wikitech.wikimedia.org/wiki/SWAP
#
class role::swap {
    system::role { 'SWAP (Jupyter Notebook)': }
    include ::standard
    include ::profile::swap
    include ::profile::analytics::cluster::client
}
