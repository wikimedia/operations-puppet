# == Class: profile::homer
#
# This class installs & manages Homer, a network configuration management tool.

class profile::homer (
    Stdlib::Host $private_git_peer = lookup('profile::homer::private_git_peer'),
    String $nb_ro_token = lookup('profile::netbox::tokens::read_only'),
    Stdlib::HTTPSUrl $nb_api = lookup('profile::netbox::netbox_api'),
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
        nb_token         => $nb_ro_token,
        nb_api           => $nb_api,
    }
}
