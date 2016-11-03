# == Class role::paws_internal::jupyterhub
# Role for setting up PAWS Internal - Jupyterhub service running on analytics cluster
#
# See https://wikitech.wikimedia.org/wiki/PAWS/Internal for more info
class role::paws_internal::jupyterhub {

    include ::base::firewall
    include ::statistics::packages

    class { '::jupyterhub':
        base_path   => '/srv/paws-internal',
        wheels_repo => 'operations/wheels/paws-internal',
    }
}
