# == Class role::paws_internal::jupyterhub
# Role for setting up PAWS Internal - Jupyterhub service running on analytics cluster
class role::paws_internal::jupyterhub {

    class { 'jupyterhub::base':
        base_dir         => '/srv/paws-internal',
        wheels_repo_url  => 'https://gerrit.wikimedia.org/r/p/operations/wheels/paws-internal.git',
    }
}
