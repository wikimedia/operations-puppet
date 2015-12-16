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
class puppet::self::master(
    $server,
    $enc_script_path = undef,
) {

    $server_desc = $server ? {
        'localhost' => 'Puppetmaster for itself',
        default     => 'Puppetmaster for project labs instances',
    }

    system::role { 'puppetmaster':
        description  => $server_desc,
    }

    class { '::puppetmaster::geoip':
        fetch_private => false,
        use_proxy     => false,
    }

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
            'eqiad' => '10.68.16.0/21',
        }
    }

    # If localhost, then just name the cert 'localhost'.
    $certname = $server ? {
        'localhost' => 'localhost',
        default     => $fqdn
    }

    # We'd best be sure that our ldap config is set up properly
    # before puppet goes to work.
    class { 'puppet::self::config':
        is_puppetmaster      => true,
        server               => $server,
        bindaddress          => $bindaddress,
        puppet_client_subnet => $puppet_client_subnet,
        certname             => $certname,
        enc_script_path      => $enc_script_path,
        require              => File['/etc/ldap/ldap.conf', '/etc/ldap.conf', '/etc/nslcd.conf'],
    }
    class { 'puppet::self::gitclone':
        require => Class['puppet::self::config'],
    }

    package { [
        'vim-puppet',
        'puppet-el',
        'rails',
        'ruby-sqlite3',
        'ruby-ldap',
        'ruby-httpclient',
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

    file { '/etc/puppet/hieradata':
        ensure => link,
        target => "${puppet::self::gitclone::gitdir}/operations/puppet/hieradata",
        force  => true,
    }

    service { 'puppetmaster':
        ensure    => 'running',
        require   => Package['puppetmaster'],
        subscribe => [Class['puppet::self::config'],
                      File['/etc/puppet/hieradata'],
                      File['/etc/puppet/hiera.yaml']],
    }

    include puppetmaster::scripts

    ferm::service { 'puppetmaster-self':
        proto  => 'tcp',
        port   => 8141,
    }
}
