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
#
# [*active_server*]
#   FQDN of the server that should have active cronjobs pulling data.
#   To avoid pulling multiple times when role is applied on muliple nodes for a standby-scenario.
#
class librenms(
    $active_server,
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

    file { '/srv/librenms':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { "${install_dir}/config.php":
        ensure  => present,
        owner   => 'www-data',
        group   => 'librenms',
        mode    => '0440',
        content => template('librenms/config.php.erb'),
        require => Group['librenms'],
        notify  => Systemd::Service['librenms-ircbot'],
    }

    file { $rrd_dir:
        ensure  => directory,
        mode    => '0775',
        owner   => 'www-data',
        group   => 'librenms',
        require => Group['librenms'],
    }

    logrotate::conf { 'librenms':
        ensure => present,
        source => 'puppet:///modules/librenms/logrotate',
    }

    if os_version('debian >= stretch') {

        package { [
                'php-cli',
                'php-curl',
                'php-gd',
                'php-mcrypt',
                'php-mysql',
                'php-snmp',
                'php-ldap',
            ]:
            ensure => present,
        }

    } else {

        package { [
                'php5-cli',
                'php5-curl',
                'php5-gd',
                'php5-mcrypt',
                'php5-mysql',
                'php5-snmp',
                'php5-ldap',
            ]:
            ensure => present,
        }
    }

    package { [
            'php-net-ipv6',
            'php-pear',
            'php-net-ipv4',
            'fping',
            'graphviz',
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

    include ::imagemagick::install

    if $active_server == $::fqdn {
        $cron_ensure = 'present'
        $ircbot_ensure = 'running'
    } else {
        $cron_ensure = 'absent'
        $ircbot_ensure = 'stopped'
    }

    systemd::service { 'librenms-ircbot':
        ensure  => $ircbot_ensure,
        content => template('librenms/initscripts/librenms-ircbot.systemd.erb'),
        require => [File["${install_dir}/config.php"] ],
    }

    cron { 'librenms-discovery-all':
        ensure  => $cron_ensure,
        user    => 'librenms',
        command => "${install_dir}/discovery.php -h all >/dev/null 2>&1",
        hour    => '*/6',
        minute  => '33',
        require => User['librenms'],
    }
    cron { 'librenms-discovery-new':
        ensure  => $cron_ensure,
        user    => 'librenms',
        command => "${install_dir}/discovery.php -h new >/dev/null 2>&1",
        minute  => '*/5',
        require => User['librenms'],
    }
    cron { 'librenms-poller-all':
        ensure  => $cron_ensure,
        user    => 'librenms',
        command => "python ${install_dir}/poller-wrapper.py 16 >/dev/null 2>&1",
        minute  => '*/5',
        require => User['librenms'],
    }
    cron { 'librenms-check-services':
        ensure  => $cron_ensure,
        user    => 'librenms',
        command => "${install_dir}/check-services.php >/dev/null 2>&1",
        minute  => '*/5',
        require => User['librenms'],
    }
    cron { 'librenms-alerts':
        ensure  => $cron_ensure,
        user    => 'librenms',
        command => "${install_dir}/alerts.php >/dev/null 2>&1",
        minute  => '*',
        require => User['librenms'],
    }
    cron { 'librenms-poll-billing':
        ensure  => $cron_ensure,
        user    => 'librenms',
        command => "${install_dir}/poll-billing.php >/dev/null 2>&1",
        minute  => '*/5',
        require => User['librenms'],
    }
    cron { 'librenms-billing-calculate':
        ensure  => $cron_ensure,
        user    => 'librenms',
        command => "${install_dir}/billing-calculate.php >/dev/null 2>&1",
        minute  => '01',
        require => User['librenms'],
    }
    cron { 'librenms-daily':
        ensure  => $cron_ensure,
        user    => 'librenms',
        command => "${install_dir}/daily.sh >/dev/null 2>&1",
        hour    => '0',
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
        ensure  => $cron_ensure,
        user    => 'librenms',
        command => "python ${install_dir}/purge.py --syslog --eventlog --perftimes '1 month' >/dev/null 2>&1",
        hour    => '0',
        minute  => '45',
    }
}
