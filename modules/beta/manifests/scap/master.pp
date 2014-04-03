# == Class: beta::scap::master
#
# Provisions scap components for a scap master node.
#
class beta::scap::master {
    include ::beta::config
    include ::beta::scap::target
    include rsync::server

    # Install ssh public key for mwdeploy user
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
        path        => '/data/project/apache/common-local',
        read_only   => 'true',
        hosts_allow => $::beta::config::rsync_networks,
    }

    package { 'dsh':
        ensure => present
    }

    # Setup dsh group files used by scap
    file { '/etc/dsh':
        ensure => directory,
        owner => root,
        group => root,
        mode => 0444,
        source => 'puppet:///modules/beta/dsh',
        recurse => true,
    }
}
