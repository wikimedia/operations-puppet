# == Class: profile::homer
#
# This class installs & manages Homer, a network configuration management tool.

# == Parameters
#
# $primary_server: server containing the source of truth for private data
class profile::homer (
  Stdlib::Fqdn $primary_server = lookup('profile::homer::primary_server')
  ){

    require_package('virtualenv')

    # Install the app itself
    scap::target { 'homer/deploy':
        deploy_user => 'deploy-homer',
    }

    ::keyholder::agent { 'homer':
        trusted_groups => ['ops'],
    }

    class { '::homer':  }

    if $primary_server == $::fqdn {
      $rsync_ensure = absent
    } else {
      $rsync_ensure = present
    }
    rsync::quickdatacopy { 'homer-private':
        ensure      => $rsync_ensure,
        source_host => $primary_server,
        dest_host   => $::fqdn,
        module_path => '/srv/homer/private',
    }

}
