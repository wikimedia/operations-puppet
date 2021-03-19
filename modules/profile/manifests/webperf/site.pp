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
    Stdlib::Fqdn $server_name          = lookup('profile::webperf::site::server_name'),
    Stdlib::Fqdn $arclamp_host         = lookup('arclamp_host'),
    Stdlib::Fqdn $xhgui_host           = lookup('profile::webperf::site::xhgui_host'),
    Hash[String, Hash] $swift_accounts = lookup('profile::swift::accounts'),
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

    file { '/var/www/no-robots.txt':
        ensure  => file,
        owner   => 'www-data',
        group   => 'www-data',
        content => file('profile/webperf/site/no-robots.txt'),
    }

    $swift_auth_url = $swift_accounts['performance_arclamp']['auth']
    $swift_account_name = $swift_accounts['performance_arclamp']['account_name']

    httpd::site { 'performance-wikimedia-org':
        content => template('profile/webperf/site/performance-website.erb'),
        require => Git::Clone['performance/docroot'],
    }

    file {'/etc/apache2/ports.conf':
        ensure  => file,
        content => file('profile/webperf/ports.conf'),
        notify  => Service['apache2'],
        require => Package['apache2'],
    }

    cron { 'warm_up_coal_cache':
        command => "/bin/bash -c 'for period in day week month year ; do /usr/bin/curl -s -H ${server_name} -o /dev/null \"${::fqdn}/coal/v1/metrics?period=\$period\" ; done'",
        minute  => [0, 30],
        user    => 'nobody',
    }

    ensure_packages(['libapache2-mod-uwsgi'])

    base::service_auto_restart { 'apache2': }
}
