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
    Stdlib::Fqdn $active_server,
    Hash $config={},
    Stdlib::Unixpath $install_dir='/srv/librenms',
    Stdlib::Unixpath $rrd_dir="${install_dir}/rrd",
) {

    # NOTE: scap will manage the deploy user
    scap::target { 'librenms/librenms':
        deploy_user => 'deploy-librenms',
    }

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
        groups     => ['deploy-librenms'],
        require    => Scap::Target['librenms/librenms'],
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
        notify  => Service['librenms-ircbot'],
    }

    file { $rrd_dir:
        ensure  => directory,
        mode    => '0775',
        owner   => 'www-data',
        group   => 'librenms',
        require => Group['librenms'],
    }

    file { $install_dir:
        mode    => 'g+w',
        require => User['librenms'],
    }

    logrotate::conf { 'librenms':
        ensure => present,
        source => 'puppet:///modules/librenms/logrotate',
    }

    apt::repository { 'wikimedia-php72':
        uri        => 'http://apt.wikimedia.org/wikimedia',
        dist       => 'stretch-wikimedia',
        components => 'component/php72',
        notify     => Exec['apt_update_php'],
    }

    # First installs can trip without this
    exec {'apt_update_php':
        command     => '/usr/bin/apt-get update',
        refreshonly => true,
        logoutput   => true,
    }

  # Package requirements from https://docs.librenms.org/Installation/Installation-Ubuntu-1804-Apache/
    package { [
        'php7.2-cli',
        'php7.2-curl',
        'php7.2-gd',
        'php7.2-json',
        'php7.2-mbstring',
        'php7.2-mysql',
        'php7.2-snmp',
        'php7.2-xml',
        'php7.2-zip',
        'php7.2-ldap',
        'libapache2-mod-php7.2']:
            ensure  => present,
            require => Apt::Repository['wikimedia-php72'],
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
    } else {
        $cron_ensure = 'absent'
    }

    systemd::service { 'librenms-ircbot':
        ensure  => $cron_ensure,
        content => template('librenms/initscripts/librenms-ircbot.systemd.erb'),
        require => [File["${install_dir}/config.php"] ],
    }

    base::service_auto_restart { 'librenms-ircbot': }

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
