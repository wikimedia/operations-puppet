# == Class: apache
#
# Provisions Apache web server package and service.
#
# This module was designed to provide a consistent interface over a
# mixed production environment which includes both Precise / Apache 2.2
# hosts and Trusty / Apache 2.4 hosts, and which utilizes Apache for
# both mission-critical services (serving MediaWiki) and small, and
# internal services.
#
# It accomodates different use-cases by expecting the caller to pass in
# full configuration files, rather than generating configuration files
# based on complex parameters and switches.
#
# The module provides forward- and back-compatibility by enabling
# mod_version, mod_filter and mod_access_compat by default, and by using
# /etc/apache2/conf-{enabled,available} to manage configuration snippets
# on both Precise and Trusty.
#
class apache {
    include apache::mod::access_compat  # enables allow/deny syntax in 2.4
    include apache::mod::filter         # enables AddOutputFilterByType in 2.4
    include apache::mod::version        # enables <IfVersion> config guards
    include apache::monitoring          # send metrics to Diamond and Ganglia
    include apache::mpm                 # prefork by default

    package { 'apache2':
        ensure => present,
    }

    service { 'apache2':
        ensure     => running,
        enable     => true,
        provider   => 'debian',
        hasrestart => true,
        restart    => '/usr/sbin/service apache2 reload',
        require    => Package['apache2'],
    }

    exec { 'apache2_test_config_and_restart':
        command     => '/usr/sbin/apache2ctl configtest',
        notify      => Exec['apache2_hard_restart'],
        require     => Service['apache2'],
        refreshonly => true,
    }

    exec { 'apache2_hard_restart':
        command     => '/usr/sbin/service apache2 restart',
        refreshonly => true,
    }

    file { [ '/etc/apache2/sites-available', '/etc/apache2/conf-available' ]:
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        require => Package['apache2'],
    }

    file { [ '/etc/apache2/sites-enabled', '/etc/apache2/conf-enabled' ]:
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        recurse => true,
        purge   => true,
        notify  => Service['apache2'],
        require => Package['apache2'],
    }

    if ubuntu_version('< trusty') {
        # Early releases of Apache manage configuration snippets in conf.d/.
        # We standardize on conf-enabled/*.conf with this small shim.
        file { '/etc/apache2/conf.d/load-conf-enabled.conf':
            content => "Include /etc/apache2/conf-enabled/*.conf\n",
            require => File['/etc/apache2/conf-enabled'],
            notify  => Service['apache2'],
        }
    }

    apache::conf { 'defaults':
        source   => 'puppet:///modules/apache/defaults.conf',
        priority => 0,
    }

    apache::site { 'dummy':
        source   => 'puppet:///modules/apache/dummy.conf',
        priority => 0,
    }

    # Set up runtime parameters and modules before sites and config snippets.
    Apache::Def <| |> -> Mod_conf <| |> -> Apache::Conf <| |>
}
