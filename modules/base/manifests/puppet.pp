class base::puppet(
    $server='puppet',
    $certname=undef,
    $dns_alt_names=undef,
    $environment=undef,
    $puppet_major_version=undef,
) {
    include ::passwords::puppet::database
    include ::base::puppet::params
    $interval = $base::puppet::params::interval
    $crontime = $base::puppet::params::crontime
    $freshnessinterval = $base::puppet::params::freshnessinterval
    $use_srv_record = $base::puppet::params::use_srv_record
    $ca_server = hiera('puppetmaster::ca_server', '')


    if $puppet_major_version == 4 {
        include base::puppet::puppet4
    }

    package { [ 'puppet', 'facter' ]:
        ensure => present,
    }

    # facter needs this for proper "virtual"/"is_virtual" resolution
    package { 'virt-what':
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

    class { '::puppet_statsd':
        statsd_host   => 'statsd.eqiad.wmnet',
        metric_format => 'puppet.<%= metric %>',
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

    $auto_puppetmaster_switching = hiera('auto_puppetmaster_switching', false)
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

    include ::base::puppet::common

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

    include ::prometheus::node_puppet_agent
}
