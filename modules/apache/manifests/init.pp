# == Class: apache
#
# Provisions Apache web server package and service.
#
class apache {
    # Strive for seamless Apache 2.2 / 2.4 compatibility
    include apache::mod::access_compat
    include apache::mod::filter
    include apache::mod::version

    package { [ 'apache2', 'apache2-mpm-prefork' ]:
        ensure => present,
    }

    service { 'apache2':
        ensure  => running,
        enable  => true,
        require => Package['apache2'],
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

    if versioncmp($::lsbdistrelease, '14.04') < 0 {
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

    # Provision Apache modules before provisioning sites and config snippets
    Apache::Mod_conf <| |> -> Apache::Conf <| |>
}
