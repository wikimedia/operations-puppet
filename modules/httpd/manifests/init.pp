# SPDX-License-Identifier: Apache-2.0
# @summary configure httpd daemon
# @param modules list of modules to install
# @param legacy_compat Use Apache 2.2 compatible syntax.
# @param period log rotation period
# @param rotate amount of log rotated files to keep
# @param enable_forensic_log turn on forensic logs
# @param extra_pkgs Extra packages to install which are not pulled in by the "apache2" base package in Debian.
# @param purge_manual_config remove any unmanaged files in the apache directory
# @param remove_default_ports if true remove the default port list
# @param http_only if true only enable to http port
# @param wait_network_online Set to true to have the service to run after
#   network-online.target. Can be used when Apache is configured to Listen to
#   an explicit IP address.
class httpd(
    Array[String]           $modules              = [],
    Wmflib::Ensure          $legacy_compat        = present,
    Enum['daily', 'weekly'] $period               = 'daily',
    Integer                 $rotate               = 30,
    Boolean                 $enable_forensic_log  = false,
    Array[String]           $extra_pkgs           = [],
    Boolean                 $purge_manual_config  = true,
    Boolean                 $remove_default_ports = false,
    Boolean                 $http_only            = false,
    Boolean                 $wait_network_online  = false,
) {
    # Package and service. Links is needed for the status page below
    $base_pkgs = ['apache2', 'links']
    $service_name = 'apache2'
    ensure_packages($base_pkgs + $extra_pkgs)

    if $remove_default_ports {
        # the file is included in apache.conf so just empty it
        file { '/etc/apache2/ports.conf':
            ensure  => file,
            content => "# Puppet: default ports are not used\n",
            notify  => Service[$service_name],
            require => Package['apache2'],
        }
    } elsif $http_only {
        # If $http_only is set to true, listen on http/80 only regardless of mod_ssl being loaded, default: false (T277989)
        file { '/etc/apache2/ports.conf':
            ensure  => file,
            content => inline_template("#This file is puppetized.\nListen 80\n"),
            notify  => Service[$service_name],
            require => Package['apache2'],
        }
    } else {
        # Use the default ports.conf if nothing else was configured.
        file { '/etc/apache2/ports.conf':
            ensure  => file,
            source  => 'puppet:///modules/httpd/default-ports.conf',
            notify  => Service[$service_name],
            require => Package['apache2'],
        }
    }

    # Ensure the directories for apache config files are in place.
    ['conf', 'env', 'sites'].each |$conf_type| {
        file { "/etc/apache2/${conf_type}-available":
            ensure  => directory,
            owner   => 'root',
            group   => 'root',
            mode    => '0755',
            require => Package['apache2'],
        }
        file { "/etc/apache2/${conf_type}-enabled":
            ensure  => directory,
            owner   => 'root',
            group   => 'root',
            mode    => '0755',
            recurse => $purge_manual_config,
            purge   => $purge_manual_config,
            require => Package['apache2'],
            notify  => Service[$service_name],
        }
    }

    file_line { 'load_env_enabled':
        line    => 'for f in /etc/apache2/env-enabled/*.sh; do [ -r "$f" ] && . "$f" >&2; done || true',
        match   => 'env-enabled',
        path    => '/etc/apache2/envvars',
        require => Package['apache2'],
    }

    # Default boilerplate configs
    httpd::conf { 'defaults':
        source   => 'puppet:///modules/httpd/defaults.conf',
        priority => 0,
    }

    httpd::site { 'dummy':
        source   => 'puppet:///modules/httpd/dummy.conf',
        priority => 0,
    }

    # Apache httpd 2.2 compatibility
    httpd::mod_conf { ['filter', 'access_compat']:
        ensure => $legacy_compat,
    }


    httpd::mod_conf { concat(['status'], $modules):
        ensure => present,
    }


    # The default mod_status configuration enables /server-status on all vhosts for
    # local requests, but it does not correctly distinguish between requests which
    # are truly local and requests that have been proxied. Because most of our
    # Apaches sit behind a reverse proxy, the default configuration is not safe, so
    # we make sure to replace it with a more conservative configuration that makes
    # /server-status accessible only to requests made via the loopback interface.
    # See T113090.

    file { [
        '/etc/apache2/mods-available/status.conf',
        '/etc/apache2/mods-enabled/status.conf',
    ]:
        ensure  => absent,
        before  => Httpd::Mod_conf['status'],
        require => Package['apache2'],
    }


    # server status page
    httpd::conf { 'server-status':
        source   => 'puppet:///modules/httpd/status.conf',
        priority => 50,
        require  => Httpd::Mod_conf['status'],
    }

    # Check the status
    file { '/usr/local/bin/apache-status':
        source => 'puppet:///modules/httpd/apache-status',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    # Forensic logging (logs requests at both beginning and end of request processing)
    if $enable_forensic_log {
        file { '/var/log/apache2/forensic':
            ensure  => directory,
            owner   => 'root',
            group   => 'adm',
            mode    => '0750',
            before  => Httpd::Conf['log_forensic'],
            require => Package['apache2'],
        }

        httpd::mod_conf { 'log_forensic':
            ensure => present,
            before => Httpd::Conf['log_forensic'],
        }

        httpd::conf { 'log_forensic':
            ensure => present,
            source => 'puppet:///modules/httpd/log_forensic.conf',
        }

        # In the case we use log_forensic, we want to
        # ensure log_forensic logs get rotated just before
        # the main logs, and that apache gets restarted afterwards.
        logrotate::conf { 'apache2':
            ensure  => present,
            content => template('httpd/logrotate.erb'),
        }
    }
    else {
        # manage logrotate periodicity and keeping period
        #
        # The augeas rule in apache::logrotate needs /etc/logrotate.d/apache2 which
        # is provided by package apache2
        augeas { 'Apache2 logs':
            lens    => 'Logrotate.lns',
            incl    => '/etc/logrotate.d/apache2',
            changes => [
                "set rule/schedule ${period}",
                "set rule/rotate ${rotate}",
            ],
            require => Package['apache2'],
        }
    }

    # When it's not, as is the case for module insertion, have a safe hard restart option
    exec { 'apache2_test_config_and_restart':
        command     => '/usr/sbin/service apache2 restart',
        onlyif      => '/usr/sbin/apache2ctl configtest',
        before      => Service[$service_name],
        refreshonly => true,
    }

    # Apache2 has After=network.target which is not sufficient to guarantee
    # the network IP addresses are available.
    # https://www.freedesktop.org/wiki/Software/systemd/NetworkTarget/
    systemd::override { 'apache2-after-network-online-target':
        ensure  => bool2str($wait_network_online, 'present', 'absent'),
        unit    => 'apache2',
        # Note: entries are appended to the existing one
        content => "[Unit]\nAfter=network-online.target\nWants=network-online.target\n",
    }

    service { $service_name:
        ensure     => running,
        enable     => true,
        hasrestart => true,
        restart    => 'systemctl reload apache2',
        require    => Package['apache2'],
    }

    $enable_htcacheclean = 'cache_disk' in $modules
    profile::auto_restarts::service { 'apache-htcacheclean':
        ensure  => $enable_htcacheclean.bool2str('present', 'absent'),
    }
    service { 'apache-htcacheclean':
        ensure => stdlib::ensure($enable_htcacheclean, 'service'),
        enable => $enable_htcacheclean,
    }
}
