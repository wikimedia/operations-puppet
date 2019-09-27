# == Class: profile::homer
#
# This class installs & manages Homer, a network configuration management tool.

class profile::homer (){

    $homer_peers = query_nodes('Class[profile::homer]').filter |$value| { $value != $::fqdn }
    if $homer_peers.length > 1 {
        fail('Profile::Homer supports only two hosts.')
    }

    require_package('virtualenv', 'make')

    # Install the app itself
    scap::target { 'homer/deploy':
        deploy_user => 'deploy-homer',
    }

    ::keyholder::agent { 'homer':
        trusted_groups => ['ops'],
    }

    class { '::homer':
        private_git_peer => $homer_peers[0],
    }

    # TODO: remove once absented
    rsync::quickdatacopy { 'homer-private':
        ensure      => absent,
        source_host => 'cumin1001.eqiad.wmnet',
        dest_host   => $::fqdn,
        module_path => '/srv/homer/private',
    }

}
