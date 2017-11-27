# == Class: role::notebook
#
class role::notebook {
    system::role { 'role::notebook':
        description => 'PAWS Internal - Jupyter Hub node, Analytics cluster client  ',
    }

    include ::profile::base::firewall
    include ::profile::jupyterhub
    include ::profile::analytics::cluster::client
    class { 'standard': }
}