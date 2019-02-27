# == Class: profile::webperf::site
#
# This profile provisions <https://performance.wikimedia.org>,
# a static site with web performance dashboards.
#
# === Parameters
#
# [*server_name*]
#   Server name for the Apache VirtualHost of this site.
#
# [*arclamp_host*]
#   HTTP host address where Arc Lamp artefacts are served (hostname or IP, port allowed).
#   For example "prof.example" or "127.0.0.2:8000".
#   Optional. If undefined, the "/arclamp" path is not proxied.
#
# [*xhgui_host*]
#   HTTP host address where the XHGui application is served (hostname or IP, port allowed).
#   For example "xhgui.example" or "127.0.0.3:8000".
#   Optional. If undefined, the "/xhgui" path is not proxied.
#
class profile::webperf::site (
    $server_name = hiera('profile::webperf::site::server_name'),
    $arclamp_host = hiera('arclamp_host', undef),
    $xhgui_host = hiera('profile::webperf::site::xhgui_host', undef)
) {

    require ::profile::webperf::coal_web

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

    cron { 'warm_up_coal_cache':
        command => "/bin/bash -c 'for period in day week month year ; do /usr/bin/curl -s -H ${server_name} -o /dev/null \"${::fqdn}/coal/v1/metrics?period=\$period\" ; done'",
        minute  => [0, 30],
        user    => 'nobody',
    }

    require_package('libapache2-mod-uwsgi')

}
