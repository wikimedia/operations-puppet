# == Class: profile::performance::site
#
# This profile provisions <https://performance.wikimedia.org>,
# a static site with web performance dashboards.
#
# === Parameters
#
# [*server_name*]
#   Server name for the Apache VirtualHost of this site.
#
# [*xenondata_host*]
#   HTTP host address where Xenon data is served (hostname or IP, port allowed).
#   For example "prof.example" or "127.0.0.2:8000".
#   Optional. If undefined, the "/xenon" path is not proxied.
#
# [*xhgui_host*]
#   HTTP host address where the XHGui application is served (hostname or IP, port allowed).
#   For example "xhgui.example" or "127.0.0.3:8000".
#   Optional. If undefined, the "/xhgui" path is not proxied.
#
class profile::performance::site (
    $server_name = hiera('profile::performance::site::server_name'),
    $xenondata_host = hiera('profile::performance::site::xenondata_host', undef),
    $xhgui_host = hiera('profile::performance::site::xhgui_host', undef)
) {

    require ::profile::performance::coal

    file { '/srv/org':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    file { '/srv/org/wikimedia':
        ensure => directory,
        owner  => 'www-data',
        group  => 'www-data',
    }

    git::clone { 'performance/docroot':
        ensure    => latest,
        owner     => 'www-data',
        group     => 'www-data',
        directory => '/srv/org/wikimedia/performance',
        notify    => Service['apache2'],
        require   => Package['apache2']
    }

    # Allow traffic to port 80 from internal networks
    ferm::service { 'performance-website-global':
        proto  => 'tcp',
        port   => '80',
        srange => '$CACHES',
    }

    httpd::site { 'performance-wikimedia-org':
        content => template('profile/performance/site/performance-website.erb'),
        require => Git::Clone['performance/docroot'],
    }

    require_package('libapache2-mod-uwsgi')

}
