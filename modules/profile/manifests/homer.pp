# == Class: profile::homer
#
# This class installs & manages Homer, a network configuration management tool.

class profile::homer (
    Stdlib::Host $private_git_peer = lookup('profile::homer::private_git_peer'),
){

    require_package('virtualenv', 'make')

    # Install the app itself
    scap::target { 'homer/deploy':
        deploy_user => 'deploy-homer',
    }

    keyholder::agent { 'homer':
        trusted_groups => ['ops'],
    }

    class { 'homer':
        private_git_peer => $private_git_peer,
    }
}
