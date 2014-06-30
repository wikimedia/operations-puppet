class base::puppet($server='puppet', $certname=undef) {

    include passwords::puppet::database
    include base::puppet::params
    $interval = $base::puppet::params::interval
    $crontime = $base::puppet::params::crontime
    $freshnessinterval = $base::puppet::params::freshnessinterval


    package { [ 'puppet', 'facter', 'coreutils' ]:
        ensure  => latest,
        require => Apt::Puppet['base']
    }

    if $::lsbdistid == 'Ubuntu' and (versioncmp($::lsbdistrelease, '10.04') == 0 or versioncmp($::lsbdistrelease, '8.04') == 0) {
        package {'timeout':
            ensure => latest,
        }
    }

    # monitoring via snmp traps
    # TODO: Remove after successful purging
    package { 'snmp':
        ensure => purged,
    }

    file { '/etc/snmp':
        ensure  => absent,
    }

    file { '/etc/snmp/snmp.conf':
        ensure  => absent,
    }
    # end of monitoring via snmp traps

    file { '/etc/default/puppet':
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/base/puppet/puppet.default',
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

    file { '/etc/puppet/puppet.conf.d/10-main.conf':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('base/puppet.conf.d/10-main.conf.erb'),
        notify  => Exec['compile puppet.conf'],
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

    file { '/etc/init.d/puppet':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/base/puppet/puppet.init',
    }

    class { 'puppet_statsd':
        statsd_host   => 'statsd.eqiad.wmnet',
        metric_format => 'puppet.<%= metric %>',
    }

    # Compile /etc/puppet/puppet.conf from individual files in /etc/puppet/puppet.conf.d
    exec { 'compile puppet.conf':
        path        => '/usr/bin:/bin',
        command     => "cat /etc/puppet/puppet.conf.d/??-*.conf > /etc/puppet/puppet.conf",
        refreshonly => true,
    }

    ## do not use puppet agent
    service {'puppet':
        ensure => stopped,
        enable => false,
    }

    file { '/etc/cron.d/puppet':
        require => File['/etc/default/puppet'],
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('base/puppet.cron.erb'),
    }

    file { '/etc/logrotate.d/puppet':
        mode   => '0444',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/base/logrotate/puppet',
    }

    # Report the last puppet run in MOTD
    if $::lsbdistid == 'Ubuntu' and versioncmp($::lsbdistrelease, '9.10') >= 0 {
        file { '/etc/update-motd.d/97-last-puppet-run':
            owner   => 'root',
            group   => 'root',
            mode    => '0555',
            source  => 'puppet:///modules/base/puppet/97-last-puppet-run',
        }
    }
}

