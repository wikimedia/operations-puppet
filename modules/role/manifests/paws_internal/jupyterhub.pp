# == Class role::paws_internal
# Role for PAWS Internal (Jupyterhub service running on analytics cluster)
class role::paws_internal {

    class { 'jupyterhub::base':
        $base_dir => '/srv/paws-internal',
    }
}
