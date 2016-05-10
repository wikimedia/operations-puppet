# == Class role::paws_internal::jupyterhub
# Role for setting up PAWS Internal - Jupyterhub service running on analytics cluster
class role::paws_internal::jupyterhub {

    class { '::jupyterhub':
        base_path   => '/srv/paws-internal',
        wheels_repo => 'operations/wheels/paws-internal',
    }
}
