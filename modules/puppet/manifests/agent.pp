# @summary install and configure puppet agent
# @param manage_ca_file if true manage the puppet ca file
# @param ca_file_path the path to the ca file
# @param ca_server the ca server
# @param server the puppet server
# @param certname the agent certname
# @param dns_alt_names a list of dns alt names
# @param environment the agent environment
# @param serialization_format the serilasation format of catalogs
# @param ca_source to source of the CA file
# @param certificate_revocation The level of certificate revocation to perform
class puppet::agent(
    Boolean                         $manage_ca_file         = false,
    Stdlib::Unixpath                $ca_file_path           = '/var/lib/puppet/ssl/certs/ca.pem',
    Optional[String[1]]             $ca_server              = undef,
    Stdlib::Host                    $server                 = 'puppet',
    Optional[String[1]]             $certname               = undef,
    Array[Stdlib::Fqdn]             $dns_alt_names          = [],
    Optional[String[1]]             $environment            = undef,
    Enum['pson', 'json', 'msgpack'] $serialization_format   = 'json',
    Optional[Stdlib::Filesource]    $ca_source              = undef,
    Optional[Enum['chain', 'leaf']] $certificate_revocation = undef,
) {
    # augparse is required to resolve the augeasversion in facter3
    # facter needs virt-what for proper "virtual"/"is_virtual" resolution
    package { [ 'facter', 'puppet', 'augeas-tools', 'virt-what' ]:
        ensure => present,
    }

    if $manage_ca_file {
        unless $ca_source {
          fail('require ca_source when manage_ca: true')
        }
        file{ $ca_file_path:
            ensure => file,
            owner  => 'puppet',
            group  => 'puppet',
            mode   => '0644',
            source => $ca_source,
        }
    }
    file { '/etc/puppet/puppet.conf':
        ensure => 'file',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        notify => Exec['compile puppet.conf'],
    }

    file { '/etc/puppet/puppet.conf.d/':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0550',
    }

    file { ['/etc/puppetlabs/','/etc/puppetlabs/facter/']:
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    file { '/etc/puppetlabs/facter/facter.conf':
        ensure  => 'file',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///modules/base/puppet/facter.conf',
        require => File['/etc/puppetlabs/facter/'],
    }

    puppet::config { 'main':
        prio    => 10,
        content => template('base/puppet.conf.d/10-main.conf.erb'),
    }

    # Compile /etc/puppet/puppet.conf from individual files in /etc/puppet/puppet.conf.d
    exec { 'compile puppet.conf':
        path        => '/usr/bin:/bin',
        command     => 'cat /etc/puppet/puppet.conf.d/??-*.conf > /etc/puppet/puppet.conf',
        refreshonly => true,
    }

    ## do not use puppet agent, use a cron-based puppet-run instead
    service {'puppet':
        ensure => stopped,
        enable => false,
    }

}
