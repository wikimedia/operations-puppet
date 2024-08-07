# SPDX-License-Identifier: Apache-2.0
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
#   FQDN of the server that should have active systemd timer jobs pulling data.
#   To avoid pulling multiple times when role is applied on muliple nodes for a standby-scenario.
#
class librenms(
    Stdlib::Fqdn     $active_server,
    String           $laravel_app_key,
    Hash             $config          = {},
    Stdlib::Unixpath $install_dir     = '/srv/librenms',
    Stdlib::Unixpath $rrd_dir         = "${install_dir}/rrd",
) {

    ensure_packages([
        'fping',
        'graphviz',
        'ipmitool',
        'libapache2-mod-php',
        'nmap',
        'php-cli',
        'php-curl',
        'php-gd',
        'php-json',
        'php-mbstring',
        'php-mysql',
        'php-pear',
        'php-snmp',
        'php-xml',
        'php-zip',
        'python3-dotenv',
        'python3-pymysql',
        'rrdtool',
        'snmp',
        'snmp-mibs-downloader',
        'whois',
    ])

    # NOTE: scap will manage the deploy user
    scap::target { 'librenms/librenms':
        deploy_user => 'deploy-librenms',
    }

    $librenms_uid = assert_type(Admin::UID::System::Global, 921)
    $librenms_gid = assert_type(Admin::UID::System::Global, $librenms_uid)

    systemd::sysuser { 'librenms':
        ensure            => present,
        id                => "${librenms_uid}:${librenms_gid}",
        description       => 'LibreNMS system user',
        additional_groups => ['deploy-librenms'],
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
    }

    file { '/var/log/librenms/librenms.log':
        ensure => present,
        owner  => 'www-data',
        group  => 'librenms',
        mode   => '0660',
    }

    file { "${install_dir}/config.php":
        ensure    => present,
        owner     => 'www-data',
        group     => 'librenms',
        mode      => '0440',
        show_diff => false,
        content   => template('librenms/config.php.erb'),
    }

    file { "${install_dir}/.env":
        ensure    => present,
        owner     => 'www-data',
        group     => 'librenms',
        mode      => '0440',
        show_diff => false,
        content   => template('librenms/.env.erb'),
    }

    file { "${install_dir}/storage":
        ensure  => directory,
        owner   => 'www-data',
        group   => 'librenms',
        mode    => '0660',
        recurse => true,
    }

    # librenms writes the session files as 0644 as such we
    # disable recurse and only manage the directory
    file { "${install_dir}/storage/framework/sessions/":
        ensure => directory,
        owner  => 'www-data',
        group  => 'librenms',
        mode   => '0660',
    }

    # "lnms" insists on being run as its owner user, and 'daily.sh' runs
    # as 'librenms'
    file { "${install_dir}/lnms":
        ensure => present,
        owner  => 'librenms',
        group  => 'librenms',
        mode   => '0755',
    }

    file { $rrd_dir:
        ensure => directory,
        mode   => '0775',
        owner  => 'www-data',
        group  => 'librenms',
    }

    # This is to allow various lock files to be created by the systemd jobs
    file { $install_dir:
        mode  => 'g+w',
        owner => 'deploy-librenms',
        group => 'librenms',
        links => follow,
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

    include imagemagick::install

    $timer_ensure = ($active_server == $::fqdn) ? {
        true    => 'present',
        default => 'absent',
    }

    systemd::timer::job { 'librenms-discovery-all':
        ensure             => $timer_ensure,
        description        => 'Regular jobs for running librenms discovery',
        user               => 'librenms',
        monitoring_enabled => false,
        logging_enabled    => false,
        command            => "${install_dir}/discovery.php -h all",
        interval           => {'start' => 'OnCalendar', 'interval' => '*-*-* 0/6:33:0'},
        syslog_identifier  => 'librenms-discovery-all',
    }

    systemd::timer::job { 'librenms-discovery-new':
        ensure             => $timer_ensure,
        description        => 'Regular jobs for running librenms discovery-new',
        user               => 'librenms',
        monitoring_enabled => false,
        logging_enabled    => false,
        command            => "${install_dir}/discovery.php -h new",
        interval           => {'start' => 'OnCalendar', 'interval' => '*-*-* *:0/5:0'},
        syslog_identifier  => 'librenms-discovery-new',
    }

    systemd::timer::job { 'librenms-poller-all':
        ensure             => $timer_ensure,
        description        => 'Regular jobs for running librenms poller',
        user               => 'librenms',
        monitoring_enabled => false,
        logging_enabled    => false,
        command            => "${install_dir}/poller-wrapper.py 16",
        interval           => {'start' => 'OnCalendar', 'interval' => '*-*-* *:0/5:0'},
        syslog_identifier  => 'librenms-poller-all',
    }

    systemd::timer::job { 'librenms-check-services':
        ensure             => $timer_ensure,
        description        => 'Regular jobs for running librenms check services',
        user               => 'librenms',
        monitoring_enabled => false,
        logging_enabled    => false,
        command            => "${install_dir}/check-services.php",
        interval           => {'start' => 'OnCalendar', 'interval' => '*-*-* *:0/5:0'},
        syslog_identifier  => 'librenms-check-services',
    }

    systemd::timer::job { 'librenms-alerts':
        ensure             => $timer_ensure,
        description        => 'Regular jobs for running librenms alerts',
        user               => 'librenms',
        monitoring_enabled => false,
        logging_enabled    => false,
        command            => "${install_dir}/alerts.php",
        interval           => {'start' => 'OnCalendar', 'interval' => 'minutely'},
        syslog_identifier  => 'librenms-alerts',
    }

    systemd::timer::job { 'librenms-poll-billing':
        ensure             => $timer_ensure,
        description        => 'Regular jobs for running librenms poll billing',
        user               => 'librenms',
        monitoring_enabled => false,
        logging_enabled    => false,
        command            => "${install_dir}/poll-billing.php",
        interval           => {'start' => 'OnCalendar', 'interval' => '*-*-* *:0/5:0'},
        syslog_identifier  => 'librenms-poll-billing',
    }

    systemd::timer::job { 'librenms-billing-calculate':
        ensure             => $timer_ensure,
        description        => 'Regular jobs for running librenms calculate billing',
        user               => 'librenms',
        monitoring_enabled => false,
        logging_enabled    => false,
        command            => "${install_dir}/billing-calculate.php",
        interval           => {'start' => 'OnCalendar', 'interval' => '*-*-* *:01:0'},
        syslog_identifier  => 'librenms-billing-calculate',
    }

    systemd::timer::job { 'librenms-daily':
        ensure             => $timer_ensure,
        description        => 'Regular jobs for running librenms daily work',
        user               => 'librenms',
        monitoring_enabled => false,
        logging_enabled    => false,
        command            => "${install_dir}/daily.sh",
        interval           => {'start' => 'OnCalendar', 'interval' => '*-*-* 01:01:0'},
        syslog_identifier  => 'librenms-daily',
    }

    # syslog script, in an install_dir-agnostic location
    # used by librenms::syslog or a custom alternative placed manually.
    file { '/usr/local/sbin/librenms-syslog':
        ensure => link,
        target => "${install_dir}/syslog.php",
    }
}
