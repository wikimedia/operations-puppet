# == Class: beta::scap::master
#
# Provisions scap components for a scap master node.
#
class beta::scap::master {
    include ::beta::config
    include ::beta::scap::target
    include rsync::server

    # Install ssh private key for mwdeploy user
    file { '/var/lib/mwdeploy/.ssh':
        ensure => directory,
        owner  => 'mwdeploy',
        group  => 'mwdeploy',
        mode   => '0700',
    }
    file { '/var/lib/mwdeploy/.ssh/id_rsa':
        owner   => 'mwdeploy',
        group   => 'mwdeploy',
        mode    => '0600',
        source  => 'puppet:///private/scap/id_rsa',
        require => File['/var/lib/mwdeploy/.ssh'],
    }

    # Run an rsync server
    rsync::server::module { 'common':
        path        => $::beta::config::scap_stage_dir,
        read_only   => 'yes',
        hosts_allow => $::beta::config::rsync_networks,
    }

    package { 'dsh':
        ensure => present
    }

    # Setup dsh configuration files used by scap
    file { '/etc/dsh':
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///modules/beta/dsh',
        recurse => true,
    }

    # Install a scap runner script for commmand line or jenkins use
    file { '/usr/local/bin/wmf-beta-scap':
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        source  => 'puppet:///modules/beta/wmf-beta-scap',
    }

    file { '/usr/local/apache':
        ensure  => directory,
    }
}
