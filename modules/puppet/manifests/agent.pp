# @summary install and configure puppet agent
# @param ca_server the ca server
# @param server the puppet server
# @param use_srv_records if true use SRV records to resolve the puppet server and ca server
# @param srv_domain the domain to use when resolving SRV records.  puppet will look for records al
#   _x-puppet._tcp.$srv_domain and _x-puppet-ca._tcp.$srv_domain.  if no value is provided a value
#   will be calculated based on the $::site variable
# @param certname the agent certname
# @param dns_alt_names a list of dns alt names
# @param environment the agent environment
# @param serialization_format the serilasation format of catalogs
# @param certificate_revocation The level of certificate revocation to perform
class puppet::agent (
    Optional[String[1]]                      $ca_server              = undef,
    Stdlib::Host                             $server                 = 'puppet',
    Boolean                                  $use_srv_records        = false,
    Optional[Stdlib::Fqdn]                   $srv_domain             = undef,
    Optional[String[1]]                      $certname               = undef,
    Array[Stdlib::Fqdn]                      $dns_alt_names          = [],
    Optional[String[1]]                      $environment            = undef,
    Enum['pson', 'json', 'msgpack']          $serialization_format   = 'json',
    Optional[Enum['chain', 'leaf', 'false']] $certificate_revocation = undef,
) {
    if $use_srv_records and !$srv_domain {
        fail('You must set $srv_domain when using $use_srv_records')
    }
    # augparse is required to resolve the augeasversion in facter3
    # facter needs virt-what for proper "virtual"/"is_virtual" resolution
    # TODO: use puppet-agent package name when everything is on puppet7
    # puppet is a transition package
    ensure_packages(['puppet', 'facter', 'augeas-tools', 'virt-what'])

    # these where moved out of core in puppet6
    if versioncmp($facts['puppetversion'], '6') >= 0 {
        ensure_packages(['puppet-module-puppetlabs-augeas-core'])
    }

    file { ['/etc/puppetlabs/','/etc/puppetlabs/facter/', '/etc/puppetlabs/facter/facts.d/']:
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    file { '/etc/puppetlabs/facter/facter.conf':
        ensure => 'file',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/puppet/facter.conf',
    }

    concat { '/etc/puppet/puppet.conf':
        owner => 'root',
        group => 'root',
        mode  => '0444',
    }

    concat::fragment { 'main':
        target  => '/etc/puppet/puppet.conf',
        order   => '10',
        content => template('puppet/main.conf.erb'),
    }

    ## do not use puppet agent, use a cron-based puppet-run instead
    service { 'puppet':
        ensure => stopped,
        enable => false,
    }
}
