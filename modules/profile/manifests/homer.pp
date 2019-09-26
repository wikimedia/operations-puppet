# == Class: profile::homer
#
# This class installs & manages Homer, a network configuration management tool.

# == Parameters
#
# $primary_server: server containing the source of truth for private data
class profile::homer (){

    require_package('virtualenv', 'make')

    # Install the app itself
    scap::target { 'homer/deploy':
        deploy_user => 'deploy-homer',
    }

    ::keyholder::agent { 'homer':
        trusted_groups => ['ops'],
    }

    class { '::homer':  }
}
