# @summary install and configure puppet agent
# @param manage_ca_file if true manage the puppet ca file
# @param ca_file_path the path to the ca file
# @param ca_server the ca server
# @param server the puppet server
# @param use_srv_records if true use SRV records to resolve the puppet server and ca server
# @param srv_domain the domain to use when resolving SRV records.  puppet will look for records al
#   _x-puppet._tcp.$srv_domain and _x-puppet-ca._tcp.$srv_domain
# @param certname the agent certname
# @param dns_alt_names a list of dns alt names
# @param environment the agent environment
# @param serialization_format the serilasation format of catalogs
# @param ca_source to source of the CA file
# @param certificate_revocation The level of certificate revocation to perform
class puppet::agent (
    Boolean                         $manage_ca_file         = false,
    Stdlib::Unixpath                $ca_file_path           = '/var/lib/puppet/ssl/certs/ca.pem',
    Optional[String[1]]             $ca_server              = undef,
    Stdlib::Host                    $server                 = 'puppet',
    Boolean                         $use_srv_records        = false,
    Optional[Stdlib::Fqdn]          $srv_domain             = undef,
    Optional[String[1]]             $certname               = undef,
    Array[Stdlib::Fqdn]             $dns_alt_names          = [],
    Optional[String[1]]             $environment            = undef,
    Enum['pson', 'json', 'msgpack'] $serialization_format   = 'json',
    Optional[Stdlib::Filesource]    $ca_source              = undef,
    Optional[Enum['chain', 'leaf']] $certificate_revocation = undef,
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

    if $manage_ca_file {
        unless $ca_source {
          fail('require ca_source when manage_ca: true')
        }
        file { $ca_file_path:
            ensure => file,
            owner  => 'puppet',
            group  => 'puppet',
            mode   => '0644',
            source => $ca_source,
        }
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
