# SPDX-License-Identifier: Apache-2.0
# == Class: profile::webperf::site
#
# This profile provisions the <https://performance.wikimedia.org> website.
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
    Stdlib::Fqdn $server_name                      = lookup('profile::webperf::site::server_name'),
    Stdlib::Fqdn $arclamp_host                     = lookup('arclamp_host'),
    Stdlib::Fqdn $xhgui_host                       = lookup('profile::webperf::site::xhgui_host'),
    Stdlib::Fqdn $excimer_mysql_host               = lookup('profile::webperf::site::excimer_mysql_host'),
    String $excimer_mysql_db                       = lookup('profile::webperf::site::excimer_mysql_db'),
    String $excimer_mysql_user                     = lookup('profile::webperf::site::excimer_mysql_user'),
    String $excimer_mysql_password                 = lookup('profile::webperf::site::excimer_mysql_password'),
    Hash[String, Hash] $swift_accounts             = lookup('profile::swift::accounts'),
) {
    ensure_packages(['libapache2-mod-php7.4', 'php7.4-mysql', 'mariadb-client'])

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
        ensure             => latest,
        recurse_submodules => true,
        owner              => 'www-data',
        group              => 'www-data',
        directory          => '/srv/org/wikimedia/performance',
        notify             => Service['apache2'],
        require            => Package['apache2']
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

    $excimer_baseurl = "https://${server_name}/excimer/";
    file { '/etc/excimer-ui-server':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
    $excimer_config = {
        'url' => $excimer_baseurl,
        'dsn' => "mysql:host=${excimer_mysql_host};dbname=${excimer_mysql_db};charset=utf8",
        'dbUser' => $excimer_mysql_user,
        'dbPassword' => $excimer_mysql_password,
        'logToSyslogCee' => true,
    }
    file { '/etc/excimer-ui-server/config.json':
        ensure    => file,
        show_diff => false,
        content   => Sensitive($excimer_config.to_json_pretty()),
        owner     => 'www-data',
        group     => 'www-data',
        mode      => '0600',
        require   => File['/etc/excimer-ui-server']
    }

    httpd::conf { 'excimer_config':
        content => "SetEnv EXCIMER_CONFIG_PATH /etc/excimer-ui-server/config.json\n"
    }

    $swift_auth_url = $swift_accounts['performance_arclamp']['auth']
    $swift_account_name = $swift_accounts['performance_arclamp']['account_name']

    httpd::site { 'performance-wikimedia-org':
        content => template('profile/webperf/site/performance-website.erb'),
        require => Git::Clone['performance/docroot'],
    }

    profile::auto_restarts::service { 'apache2': }
    profile::auto_restarts::service { 'envoyproxy': }
}
