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
    Stdlib::Fqdn     $active_server,
    String           $laravel_app_key,
    Hash             $config          = {},
    Stdlib::Unixpath $install_dir     = '/srv/librenms',
    Stdlib::Unixpath $rrd_dir         = "${install_dir}/rrd",
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

    file { '/var/log/librenms':
        ensure  => 'directory',
        owner   => 'www-data',
        group   => 'librenms',
        recurse => true,
        mode    => '0775',
        require => Group['librenms'],
    }

    file { "${install_dir}/config.php":
        ensure    => present,
        owner     => 'www-data',
        group     => 'librenms',
        mode      => '0440',
        show_diff => false,
        content   => template('librenms/config.php.erb'),
        require   => Group['librenms'],
    }

    file { "${install_dir}/.env":
        ensure    => present,
        owner     => 'www-data',
        group     => 'librenms',
        mode      => '0440',
        show_diff => false,
        content   => template('librenms/.env.erb'),
        require   => Group['librenms'],
    }

    file { "${install_dir}/storage":
        ensure  => directory,
        owner   => 'www-data',
        group   => 'librenms',
        mode    => '0660',
        recurse => true,
        require => Group['librenms'],
    }
    # librenms writes the session files as 0644 as such we
    # disable recurse and only manage the directory
    file { "${install_dir}/storage/framework/sessions/":
        ensure  => directory,
        owner   => 'www-data',
        group   => 'librenms',
        mode    => '0660',
        recurse => false,
        require => Group['librenms'],
    }

    file { $rrd_dir:
        ensure  => directory,
        mode    => '0775',
        owner   => 'www-data',
        group   => 'librenms',
        require => Group['librenms'],
    }

    # This is to allow various lock files to be created by the cronjobs
    file { $install_dir:
        mode    => 'g+w',
        group   => 'librenms',
        links   => follow,
        require => Group['librenms'],
    }

    file { "${install_dir}/.ircbot.alert":
        mode  => 'a+w',
    }

    file { "${install_dir}/logs":
        ensure  => directory,
        owner   => 'www-data',
        group   => 'librenms',
        mode    => '0775',
        recurse => true,
    }

    file { "${install_dir}/bootstrap/cache":
        ensure  => directory,
        owner   => 'www-data',
        group   => 'librenms',
        mode    => '0775',
        recurse => true,
    }

    logrotate::conf { 'librenms':
        ensure => present,
        source => 'puppet:///modules/librenms/logrotate',
    }

    # Package requirements from https://docs.librenms.org/Installation/Installation-Ubuntu-1804-Apache/
    if debian::codename::eq('stretch') {
        $php72_packages = [
            'php7.2-cli', 'php7.2-curl', 'php7.2-gd', 'php7.2-json', 'php7.2-mbstring', 'php7.2-mysql',
            'php7.2-snmp', 'php7.2-xml', 'php7.2-zip', 'php7.2-ldap', 'libapache2-mod-php7.2'
        ]

        apt::package_from_component { 'librenms_php72':
            component => 'component/php72',
            packages  => $php72_packages,
        }

        package { ['php-net-ipv6', 'php-net-ipv4']:
            ensure => present,
        }
    } else {
        $php_packages = ['php-cli', 'php-curl', 'php-gd', 'php-json', 'php-mbstring', 'php-mysql', 'php-snmp', 'php-xml', 'php-zip', 'php-ldap', 'libapache2-mod-php']
        package { $php_packages:
            ensure => present,
        }
    }

    ensure_packages([
            'php-pear',
            'fping',
            'graphviz',
            'ipmitool',
            'mtr-tiny',
            'nmap',
            'python3-pymysql',
            'rrdtool',
            'snmp',
            'snmp-mibs-downloader',
            'whois',
        ])

    include imagemagick::install

    $cron_ensure = ($active_server == $::fqdn) ? {
        true    => 'present',
        default => 'absent',
    }

    cron { 'librenms-discovery-all':
        ensure  => absent,
        user    => 'librenms',
        command => "${install_dir}/discovery.php -h all >/dev/null 2>&1",
        hour    => '*/6',
        minute  => '33',
        require => User['librenms'],
    }
    systemd::timer::job { 'librenms-discovery-all':
        ensure             => $cron_ensure,
        description        => 'Regular jobs for running librenms discovery',
        user               => 'librenms',
        monitoring_enabled => false,
        logging_enabled    => false,
        command            => "${install_dir}/discovery.php -h all",
        interval           => {'start' => 'OnCalendar', 'interval' => '*-*-* 0/6:33:0'},
        require            => User['librenms'],
    }
    cron { 'librenms-discovery-new':
        ensure  => absent,
        user    => 'librenms',
        command => "${install_dir}/discovery.php -h new >/dev/null 2>&1",
        minute  => '*/5',
        require => User['librenms'],
    }
    systemd::timer::job { 'librenms-discovery-new':
        ensure             => $cron_ensure,
        description        => 'Regular jobs for running librenms discovery-new',
        user               => 'librenms',
        monitoring_enabled => false,
        logging_enabled    => false,
        command            => "${install_dir}/discovery.php -h new",
        interval           => {'start' => 'OnCalendar', 'interval' => '*-*-* *:0/5:0'},
        require            => User['librenms'],
    }
    cron { 'librenms-poller-all':
        ensure  => absent,
        user    => 'librenms',
        command => "${install_dir}/poller-wrapper.py 16 >/dev/null 2>&1",
        minute  => '*/5',
        require => User['librenms'],
    }
    systemd::timer::job { 'librenms-poller-all':
        ensure             => $cron_ensure,
        description        => 'Regular jobs for running librenms poller',
        user               => 'librenms',
        monitoring_enabled => false,
        logging_enabled    => false,
        command            => "${install_dir}/poller-wrapper.py 16",
        interval           => {'start' => 'OnCalendar', 'interval' => '*-*-* *:0/5:0'},
        require            => User['librenms'],
    }
    cron { 'librenms-check-services':
        ensure  => absent,
        user    => 'librenms',
        command => "${install_dir}/check-services.php >/dev/null 2>&1",
        minute  => '*/5',
        require => User['librenms'],
    }
    systemd::timer::job { 'librenms-check-services':
        ensure             => $cron_ensure,
        description        => 'Regular jobs for running librenms check services',
        user               => 'librenms',
        monitoring_enabled => false,
        logging_enabled    => false,
        command            => "${install_dir}/check-services.php",
        interval           => {'start' => 'OnCalendar', 'interval' => '*-*-* *:0/5:0'},
        require            => User['librenms'],
    }
    cron { 'librenms-alerts':
        ensure  => absent,
        user    => 'librenms',
        command => "${install_dir}/alerts.php >/dev/null 2>&1",
        minute  => '*',
        require => User['librenms'],
    }
    systemd::timer::job { 'librenms-alerts':
        ensure             => $cron_ensure,
        description        => 'Regular jobs for running librenms alerts',
        user               => 'librenms',
        monitoring_enabled => false,
        logging_enabled    => false,
        command            => "${install_dir}/alerts.php",
        interval           => {'start' => 'OnCalendar', 'interval' => 'minutely'},
        require            => User['librenms'],
    }
    cron { 'librenms-poll-billing':
        ensure  => absent,
        user    => 'librenms',
        command => "${install_dir}/poll-billing.php >/dev/null 2>&1",
        minute  => '*/5',
        require => User['librenms'],
    }
    systemd::timer::job { 'librenms-poll-billing':
        ensure             => $cron_ensure,
        description        => 'Regular jobs for running librenms poll billing',
        user               => 'librenms',
        monitoring_enabled => false,
        logging_enabled    => false,
        command            => "${install_dir}/poll-billing.php",
        interval           => {'start' => 'OnCalendar', 'interval' => '*-*-* *:0/5:0'},
        require            => User['librenms'],
    }
    cron { 'librenms-billing-calculate':
        ensure  => absent,
        user    => 'librenms',
        command => "${install_dir}/billing-calculate.php >/dev/null 2>&1",
        minute  => '01',
        require => User['librenms'],
    }
    systemd::timer::job { 'librenms-billing-calculate':
        ensure             => $cron_ensure,
        description        => 'Regular jobs for running librenms calculate billing',
        user               => 'librenms',
        monitoring_enabled => false,
        logging_enabled    => false,
        command            => "${install_dir}/billing-calculate.php",
        interval           => {'start' => 'OnCalendar', 'interval' => '*-*-* *:01:0'},
        require            => User['librenms'],
    }
    cron { 'librenms-daily':
        ensure  => absent,
        user    => 'librenms',
        command => "${install_dir}/daily.sh >/dev/null 2>&1",
        hour    => '0',
        require => User['librenms'],
    }
    systemd::timer::job { 'librenms-daily':
        ensure             => $cron_ensure,
        description        => 'Regular jobs for running librenms daily work',
        user               => 'librenms',
        monitoring_enabled => false,
        logging_enabled    => false,
        command            => "${install_dir}/daily.sh",
        interval           => {'start' => 'OnCalendar', 'interval' => '*-*-* 01:01:0'},
        require            => User['librenms'],
    }

    # syslog script, in an install_dir-agnostic location
    # used by librenms::syslog or a custom alternative placed manually.
    file { '/usr/local/sbin/librenms-syslog':
        ensure => link,
        target => "${install_dir}/syslog.php",
    }
}
