# == Class puppet::self::config
# Configures variables and puppet config files
# for either self puppetmasters or self puppet clients.
#
# == Parameters
# $server - hostname of the puppetmaster.
# $is_puppetmaster      - Boolean. Default: false.
# $bindaddress          - Address to which a puppetmaster should listen.
#                         Unused if $is_puppetmaster is false.
# $puppet_client_subnet - Network from which to allow fileserver connections.
#                         Unused if $is_puppetmaster is false.
# $certname             - Name of the puppet CA certificate.  $fqdn
#
class puppet::self::config(
    $server,
    $is_puppetmaster      = false,
    $bindaddress          = undef,
    $puppet_client_subnet = undef,
    $certname             = $::fqdn,
    $autosign             = hiera('puppetmaster::autosigner', false),
    $use_enc              = true,
) {
    if ! $use_enc {
        fail('Ldap puppet node definitions are no longer supported.  The $use_enc param must be true.')
    }

    require_package('python3-yaml', 'python3-ldap3')

    include ::ldap::yamlcreds

    file { '/etc/puppet-enc.yaml':
        content => ordered_yaml({
            host => hiera('labs_puppet_master'),
            }),
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
    }

    file { '/usr/local/bin/puppet-enc':
        source => 'puppet:///modules/role/labs/puppet-enc.py',
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
    }

    $config = {
        'node_terminus'  => 'exec',
        'external_nodes' => '/usr/local/bin/puppet-enc',
        'dbadapter'      => 'sqlite3',
        'autosign'       => $autosign,
    }

    # This is set to something different than the default
    # /var/lib/puppet/ssl to avoid conflicts with previously
    # generated puppet certificates from the normal puppet setup.
    if $is_puppetmaster {
        $ssldir = puppet_ssldir('master')
        # include puppetmaster::ssl for self hosted
        # puppetmasters.  (This sets up the ssl directories).
        class { '::puppetmaster::ssl':
            server_name => $::fqdn,
        }

        # Make sure the puppet.conf compile (defined in base::puppet)
        # runs before puppetmaster::ssl tries to generate the puppet
        # cert.
        Exec['compile puppet.conf'] -> Class['puppetmaster::ssl']
    }
    else {
        $ssldir = puppet_ssldir('client')
        # ensure $ssldir's parent dir exists
        # so that puppet can create $ssldir.
        file { '/var/lib/puppet/client':
            ensure  => directory,
            owner   => 'puppet',
            group   => 'root',
            mode    => '0771',
            require => Class['base::puppet'],
        }
    }

    # ensure '10-main.conf is removed when 10-self.conf is present'
    Base::Puppet::Config <| title == 'main' |> {
        ensure => absent,
    }
    Base::Puppet::Config['main'] ~> Exec['compile puppet.conf']
    Base::Puppet::Config['main'] ~> Base::Puppet::Config['self']

    base::puppet::config { 'self':
        prio    => 10,
        content => template('puppet/self.conf.erb'),
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
        content => template('puppet/auth-self.conf.erb'),
    }

    file { '/etc/puppet/fileserver.conf':
        ensure  => $puppetmaster_status,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('puppet/fileserver-self.conf.erb'),
    }
}
