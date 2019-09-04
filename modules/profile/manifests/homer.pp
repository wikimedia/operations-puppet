# == Class: profile::homer
#
# This class installs & manages Homer, a network configuration management tool.

# == Parameters
#
# $primary_server: server containing the source of truth for private data
class profile::homer (
  Stdlib::Fqdn $primary_server = lookup('profile::homer::primary_server')
  ){
    # Install the app itself
    scap::target { 'homer/deploy':
        deploy_user => 'homer',
    }

    ::keyholder::agent { 'homer':
        require        => Group['homer'],
        trusted_groups => ['homer', 'ops'],
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
