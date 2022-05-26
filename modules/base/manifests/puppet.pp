class base::puppet(
    Boolean                         $manage_ca_file         = false,
    Stdlib::Unixpath                $ca_file_path           = '/var/lib/puppet/ssl/certs/ca.pem',
    String                          $ca_server              = '',
    Stdlib::Host                    $server                 = 'puppet',
    Optional[String]                $certname               = undef,
    Array[Stdlib::Fqdn]             $dns_alt_names          = [],
    Optional[String]                $environment            = undef,
    Integer                         $interval               = 30,
    Enum['pson', 'json', 'msgpack'] $serialization_format   = 'json',
    Optional[Stdlib::Filesource]    $ca_source              = undef,
    Optional[Enum['chain', 'leaf']] $certificate_revocation = undef,
) {
    $crontime          = fqdn_rand(60, 'puppet-params-crontime')

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

    base::puppet::config { 'main':
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

    file { '/usr/local/share/bash/puppet-common.sh':
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/base/puppet/puppet-common.sh',
    }

    file { '/usr/local/sbin/puppet-run':
        mode    => '0555',
        owner   => 'root',
        group   => 'root',
        content => template('base/puppet-run.erb'),
    }

    file { '/usr/local/sbin/disable-puppet':
        ensure => present,
        mode   => '0550',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/base/puppet/disable-puppet',
    }

    file { '/usr/local/sbin/enable-puppet':
        ensure => present,
        mode   => '0550',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/base/puppet/enable-puppet',
    }

    file { '/usr/local/sbin/run-puppet-agent':
        ensure => present,
        mode   => '0550',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/base/puppet/run-puppet-agent',
    }

    file { '/usr/local/sbin/run-no-puppet':
        mode   => '0550',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/base/puppet/run-no-puppet',
    }

    file { '/etc/cron.d/puppet':
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('base/puppet.cron.erb'),
        require => File['/usr/local/sbin/puppet-run'],
    }

    logrotate::rule { 'puppet':
        ensure       => present,
        file_glob    => '/var/log/puppet /var/log/puppet.log',
        frequency    => 'daily',
        compress     => true,
        missing_ok   => true,
        not_if_empty => true,
        rotate       => 7,
    }

    rsyslog::conf { 'puppet-agent':
        source   => 'puppet:///modules/base/rsyslog.d/puppet-agent.conf',
        priority => 10,
        require  => File['/etc/logrotate.d/puppet'],
    }

    # Mode 0751 to make sure non-root users can access
    # /var/lib/puppet/state/agent_disabled.lock to check if puppet is enabled
    file { '/var/lib/puppet':
        ensure => directory,
        owner  => 'puppet',
        group  => 'puppet',
        mode   => '0751',
    }

    file { '/usr/local/bin/puppet-enabled':
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/base/puppet/puppet-enabled',
    }

    motd::script { 'last-puppet-run':
        ensure   => present,
        priority => 97,
        source   => 'puppet:///modules/base/puppet/97-last-puppet-run',
    }
}
