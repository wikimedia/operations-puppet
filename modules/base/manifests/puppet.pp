class base::puppet(
    Stdlib::Host     $ca_server                   = 'puppet-ca',
    Stdlib::Host     $server                      = 'puppet',
    Optional[String] $certname                    = undef,
    Optional[String] $dns_alt_names               = undef,
    Optional[String] $environment                 = undef,
    Integer          $interval                    = 30,
    Boolean          $auto_puppetmaster_switching = false,
    Integer[4,5]     $puppet_major_version = 4,
    Integer[2,3]     $facter_major_version = 2,
) {
    include ::passwords::puppet::database # lint:ignore:wmf_styleguide

    $crontime          = fqdn_rand(60, 'puppet-params-crontime')

    if os_version('debian < buster') {
      if $puppet_major_version == 5 {
        apt::repository {'component-puppet5':
          uri        => 'http://apt.wikimedia.org/wikimedia',
          dist       => "${::lsbdistcodename}-wikimedia",
          components => 'component/puppet5',
          before     => Package['puppet'],
        }
      } elsif $puppet_major_version == 4 {
        apt::repository {'component-puppet5':
          ensure => absent,
        }
      }

      if $facter_major_version == 3 {
        apt::repository {'component-facter3':
          uri        => 'http://apt.wikimedia.org/wikimedia',
          dist       => "${::lsbdistcodename}-wikimedia",
          components => 'component/facter3',
          before     => Package['facter'],
        }
      } elsif $facter_major_version == 2 {
        apt::repository {'component-facter3':
          ensure => absent,
        }
      }
    } elsif $facter_major_version != 3 or puppet_major_version != 5 {
      warning('buster only supports puppet5 and facter3')
    }

    # augparse is required to resolve the augeasversion in facter3
    # facter needs virt-what for proper "virtual"/"is_virtual" resolution
    package { [ 'puppet', 'facter', 'augeas-tools', 'virt-what' ]:
        ensure => present,
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

    base::puppet::config { 'main':
        prio    => 10,
        content => template('base/puppet.conf.d/10-main.conf.erb'),
    }

    if $::realm == 'labs' {
        # Clear master certs if puppet.conf changed
        exec { 'delete master certs':
            path        => '/usr/bin:/bin',
            command     => 'rm -f /var/lib/puppet/ssl/certs/ca.pem; rm -f /var/lib/puppet/ssl/crl.pem; rm -f /root/allowcertdeletion',
            onlyif      => 'test -f /root/allowcertdeletion',
            subscribe   => File['/etc/puppet/puppet.conf.d/10-main.conf'],
            refreshonly => true,
        }
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

    if ($auto_puppetmaster_switching) and ($::realm != 'labs') {
        fail('auto_puppetmaster_switching should never, ever be set on a production host.')
    }
    if ($auto_puppetmaster_switching) and (defined(Class['role::puppetmaster::standalone'])) {
        fail('auto_puppetmaster_switching should only be applied on puppet clients; behavior on masters is undefined.')
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
