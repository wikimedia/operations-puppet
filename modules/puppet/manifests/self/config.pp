# == Class puppet::self::config
# Configures variables and puppet config files
# for either self puppetmasters or self puppet clients.
# This inherits from base::puppet in order to override
# default puppet config files.
#
# == Parameters
# $server - hostname of the puppetmaster.
# $is_puppetmaster      - Boolean. Default: false.
# $bindaddress          - Address to which a puppetmaster should listen.
#                         Unused if $is_puppetmaster is false.
# $puppet_client_subnet - Network from which to allow fileserver connections.
#                         Unused if $is_puppetmaster is false.
# $certname             - Name of the puppet CA certificate.  Default: "$ec2_instance_id.$domain", e.g. the labs instance name:  i-00000699.pmtpa.wmflabs.
#
class puppet::self::config(
    $server,
    $is_puppetmaster      = false,
    $bindaddress          = undef,
    $puppet_client_subnet = undef,
    $certname             = "${::ec2_instance_id}.${::domain}"
) inherits base::puppet {
    include ldap::role::config::labs

    $ldapconfig = $ldap::role::config::labs::ldapconfig
    $basedn = $ldapconfig['basedn']

    $config = {
        'dbadapter'     => 'sqlite3',
        'node_terminus' => 'ldap',
        'ldapserver'    => $ldapconfig['servernames'][0],
        'ldapbase'      => "ou=hosts,${basedn}",
        'ldapstring'    => '(&(objectclass=puppetClient)(associatedDomain=%s))',
        'ldapuser'      => $ldapconfig['proxyagent'],
        'ldappassword'  => $ldapconfig['proxypass'],
        'ldaptls'       => true
    }

    # This is set to something different than the default
    # /var/lib/puppet/ssl to avoid conflicts with previously
    # generated puppet certificates from the normal puppet setup.
    if $is_puppetmaster {
        $ssldir = '/var/lib/puppet/server/ssl'
        # include puppetmaster::ssl for self hosted
        # puppetmasters.  (This sets up the ssl directories).
        class { 'puppetmaster::ssl':
            server_name => $::fqdn,
            ca          => true,
        }

        # Make sure the puppet.conf compile (defined in base::puppet)
        # runs before puppetmaster::ssl tries to generate the puppet
        # cert.
        Exec['compile puppet.conf'] -> Class['puppetmaster::ssl']
    }
    else {
        $ssldir = '/var/lib/puppet/client/ssl'
        # ensure $ssldir's parent dir exists
        # so that puppet can create $ssldir.
        file { '/var/lib/puppet/client':
            ensure  => directory,
            owner   => 'puppet',
            group   => 'root',
            mode    => '0771',
            require => Package['puppet'],
        }
    }

    File['/etc/puppet/puppet.conf.d/10-main.conf'] {
        ensure => absent,
    }

    file { '/etc/puppet/puppet.conf.d/10-self.conf':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('puppet/puppet.conf.d/10-self.conf.erb'),
        require => [File['/etc/puppet/puppet.conf.d'], File['/etc/puppet/puppet.conf.d/10-main.conf']],
        notify  => Exec['compile puppet.conf'],
    }
    $puppetmaster_status = $is_puppetmaster ? {
            true    => 'file',
            default => absent,
    }

    file { '/etc/puppet/auth.conf':
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('puppet/auth-self.conf.erb')
    }

    file { '/etc/puppet/fileserver.conf':
        ensure  => $puppetmaster_status,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('puppet/fileserver-self.conf.erb'),
    }
}
