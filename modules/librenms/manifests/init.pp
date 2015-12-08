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
#   Installation directory for LibreNMS. Defaults to /srv/librenms.
#
# [*rrd_dir*]
#   Location where RRD files are going to be placed. Defaults to "rrd" under
#   *install_dir*.
#
class librenms(
    $config={},
    $install_dir='/srv/librenms',
    $rrd_dir="${install_dir}/rrd",
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

    file { '/etc/logrotate.d/librenms':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/librenms/logrotate',
    }

    package { [
            'php5-cli',
            'php5-gd',
            'php5-mcrypt',
            'php5-mysql',
            'php5-snmp',
            'php-net-ipv4',
            'php-net-ipv6',
            'php-pear',
            'fping',
            'graphviz',
            'imagemagick',
            'ipmitool',
            'mtr-tiny',
            'nmap',
            'python-mysqldb',
            'rrdtool',
            'snmp',
            'snmp-mibs-downloader',
            'whois',
        ]:
        ensure => present,
    }

    cron { 'librenms-discovery-all':
        ensure  => present,
        user    => 'librenms',
        command => "${install_dir}/discovery.php -h all >/dev/null 2>&1",
        hour    => '*/6',
        minute  => '33',
        require => User['librenms'],
    }
    cron { 'librenms-discovery-new':
        ensure  => present,
        user    => 'librenms',
        command => "${install_dir}/discovery.php -h new >/dev/null 2>&1",
        minute  => '*/5',
        require => User['librenms'],
    }
    cron { 'librenms-poller-all':
        ensure  => present,
        user    => 'librenms',
        command => "python ${install_dir}/poller-wrapper.py 16 >/dev/null 2>&1",
        minute  => '*/5',
        require => User['librenms'],
    }
    cron { 'librenms-check-services':
        ensure  => present,
        user    => 'librenms',
        command => "${install_dir}/check-services.php >/dev/null 2>&1",
        minute  => '*/5',
        require => User['librenms'],
    }
    cron { 'librenms-alerts':
        ensure  => present,
        user    => 'librenms',
        command => "${install_dir}/alerts.php >/dev/null 2>&1",
        minute  => '*',
        require => User['librenms'],
    }

    # syslog script, in an install_dir-agnostic location
    # used by librenms::syslog or a custom alternative placed manually.
    file { '/usr/local/sbin/librenms-syslog':
        ensure => link,
        target => "${install_dir}/syslog.php",
    }

    file { "${install_dir}/purge.py":
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/librenms/purge.py',
    }
    cron { 'purge-syslog-eventlog':
        ensure  => present,
        user    => 'librenms',
        command => "python ${install_dir}/purge.py --syslog --eventlog --perftimes '1 month' >/dev/null 2>&1",
        hour    => '0',
        minute  => '45',
    }
}
