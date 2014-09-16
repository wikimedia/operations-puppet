# == Class puppet::self::master
# Sets up a node as a puppetmaster.
# If server => localhost, then this node will
# be set up to only act as a puppetmaster for itself.
# Otherwise, this server will be able to act as a puppetmaster
# for any labs nodes that are configured using the puppet::self::client
# class with $server set to this nodes $::fqdn.
#
# This class will clone the operations/puppet git repository
# and set it up with proper symlinks in /etc/puppet.
#
# == Parameters
# $server - hostname of the puppetmaster.
#
class puppet::self::master($server) {
    system::role { 'puppetmaster':
        description  => $server ? {
            'localhost' => 'Puppetmaster for itself',
            default     => 'Puppetmaster for project labs instances',
        }
    }

    include puppet::self::geoip

    # If localhost, only bind to loopback.
    $bindaddress = $server ? {
        'localhost' => '127.0.0.1',
        default => $::ipaddress,
    }

    # If localhost, only allow this node.
    # Else allow the labs subnet.
    $puppet_client_subnet = $server ? {
        'localhost' => '127.0.0.1',
        default => $::site ? {
            'pmtpa' => '10.4.0.0/21',
            'eqiad' => '10.68.16.0/21',
        }
    }

    # If localhost, then just name the cert 'localhost'.
    # Else certname should be the labs instanceid. ($::ec2id comes from instance metadata.)
    $certname = $server ? {
        'localhost' => 'localhost',
        default     => "${::ec2id}.${::domain}"
    }

    class { 'puppet::self::config':
        is_puppetmaster      => true,
        server               => $server,
        bindaddress          => $bindaddress,
        puppet_client_subnet => $puppet_client_subnet,
        certname             => $certname,
    }
    class { 'puppet::self::gitclone':
        require => Class['puppet::self::config'],
    }

    # pin puppetmaster packages
    apt::puppet {'puppetmaster':
        packages => 'puppetmaster puppetmaster-common vim-puppet puppet-el',
        before   => Package['puppetmaster']
    }

    package { [
        'vim-puppet',
        'puppet-el',
        'rails',
        'ruby-sqlite3',
        'ruby-ldap',
    ]:
        ensure => present,
    }

    # puppetmaster is started when installed, so things must be already set
    # up by the time postinst runs; add a few require deps
    package { [ 'puppetmaster', 'puppetmaster-common' ]:
        ensure  => latest,
        require => [
            Package['rails'],
            Package['ruby-sqlite3'],
            Package['ruby-ldap'],
            Class['puppet::self::config'],
            Class['puppet::self::gitclone'],
        ],
    }

    #Set up hiera locally
    class { '::puppetmaster::hiera':
        source => 'puppet:///modules/puppetmaster/labs.hiera.yaml',
    }


    service { 'puppetmaster':
        ensure    => 'running',
        require   => Package['puppetmaster'],
        subscribe => Class['puppet::self::config'],
    }

    include puppetmaster::scripts
}
