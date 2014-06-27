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
    package { 'snmp':
        ensure => latest,
    }

    file { '/etc/snmp':
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => Package['snmp'],
    }

    file { '/etc/snmp/snmp.conf':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('base/snmp.conf.erb'),
        require => [ Package['snmp'], File['/etc/snmp'] ],
    }

    monitor_service { 'puppet freshness':
        description     => 'Puppet freshness',
        check_command   => 'puppet-FAIL',
        passive         => 'true',
        freshness       => $freshnessinterval,
        retries         => 1,
    }

    case $::realm {
        'production': {
            exec {  'neon puppet snmp trap':
                command => "snmptrap -v 1 -c public neon.wikimedia.org .1.3.6.1.4.1.33298 `hostname` 6 1004 `uptime | awk '{ split(\$3,a,\":\"); print (a[1]*60+a[2])*60 }'`",
                path    => '/bin:/usr/bin',
                require => Package['snmp'],
            }
        }
        'labs': {
            # The next two notifications are read in by the labsstatus.rb puppet report handler.
            #  It needs to know project/hostname for nova access.
            notify{"instanceproject: ${::instanceproject}":}
            notify{"hostname: ${::instancename}":}
            exec { 'puppet snmp trap':
                command => "snmptrap -v 1 -c public icinga.eqiad.wmflabs .1.3.6.1.4.1.33298 ${::instancename}.${::site}.wmflabs 6 1004 `uptime | awk '{ split(\$3,a,\":\"); print (a[1]*60+a[2])*60 }'`",
                path    => '/bin:/usr/bin',
                require => Package['snmp'],
            }
        }
        default: {
            err('realm must be either "labs" or "production".')
        }
    }

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

