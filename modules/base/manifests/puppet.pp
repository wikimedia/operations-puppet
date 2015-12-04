class base::puppet($server='puppet', $certname=undef) {

    include passwords::puppet::database
    include base::puppet::params
    $interval = $base::puppet::params::interval
    $crontime = $base::puppet::params::crontime
    $freshnessinterval = $base::puppet::params::freshnessinterval

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

    class { 'puppet_statsd':
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
    file { '/usr/local/sbin/puppet-run':
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => template('base/puppet-run.erb')
    }

    file { '/etc/cron.d/puppet':
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('base/puppet.cron.erb'),
        require => File['/usr/local/sbin/puppet-run'],
    }

    file { '/etc/logrotate.d/puppet':
        mode   => '0444',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/base/logrotate/puppet',
    }

    motd::script { 'last-puppet-run':
        ensure   => present,
        priority => 97,
        source   => 'puppet:///modules/base/puppet/97-last-puppet-run',
    }
}

