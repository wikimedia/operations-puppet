# == Class: librenms
#
# This class installs & manages LibreNMS, a fork of Observium
#
# == Parameters
#
# [*config*]
#   Configuration for LibreNMS, in a puppet hash format.
#
# [*install_dir*]
#   Installation directory for LibreNMS.
#
class librenms(
    $config,
    $install_dir='/srv/librenms',
) {
    group { 'librenms':
        ensure => present,
    }

    user { 'librenms':
        ensure     => present,
        gid        => 'librenms',
        shell      => '/bin/false',
        home       => '/nonexistent',
        system     => true,
        managehome => false,
    }

    file { $install_dir:
        ensure  => directory,
        owner   => 'www-data',
        group   => 'librenms',
        mode    => '0555',
        require => Group['librenms'],
    }

    file { "${install_dir}/config.php":
        ensure  => present,
        owner   => 'www-data',
        group   => 'librenms',
        mode    => '0440',
        content => template('librenms/config.php.erb'),
        require => Group['librenms'],
    }

    file { [ '/var/lib/librenms', '/var/lib/librenms/rrd' ]:
        ensure  => directory,
        owner   => 'librenms',
        group   => 'librenms',
        mode    => '0755',
    }

    file { '/etc/logrotate.d/librenms':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/librenms/logrotate',
    }

    package { [
            'php5-cli',
            'php5-gd',
            'php5-json',
            'php5-mcrypt',
            'php5-mysql',
            'php5-snmp',
            'php-pear',
            'fping',
            'graphviz',
            'imagemagick',
            'ipmitool',
            'mtr-tiny',
            'nmap',
            'python-mysqldb',
            'rrdtool',
            'whois',
        ]:
        ensure => present,
    }

    cron { 'librenms-discovery-all':
        ensure  => present,
        user    => 'librenms',
        command => "${install_dir}/discovery.php -h all >> /dev/null 2>&1",
        hour    => '*/6',
        minute  => '33',
        require => User['librenms'],
    }
    cron { 'librenms-discovery-new':
        ensure  => present,
        user    => 'librenms',
        command => "${install_dir}/discovery.php -h all >> /dev/null 2>&1",
        minute  => '*/5',
        require => User['librenms'],
    }
    cron { 'librenms-poller-all':
        ensure  => present,
        user    => 'librenms',
        command => "${install_dir}/poller.php -h all >> /dev/null 2>&1",
        minute  => '*/5',
        require => User['librenms'],
    }
}
