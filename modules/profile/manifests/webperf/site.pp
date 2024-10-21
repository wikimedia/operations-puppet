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
class profile::webperf::site (
    Stdlib::Fqdn $server_name                      = lookup('profile::webperf::site::server_name'),
    Stdlib::Fqdn $arclamp_host                     = lookup('arclamp_host'),
    Stdlib::Fqdn $xhgui_mysql_host                 = lookup('profile::webperf::xhgui::mysql_host'),
    String $xhgui_mysql_db                         = lookup('profile::webperf::xhgui::mysql_db'),
    String $xhgui_mysql_user                       = lookup('profile::webperf::xhgui::mysql_user'),
    String $xhgui_mysql_password                   = lookup('profile::webperf::xhgui::mysql_password'),
    String $xhgui_mysql_admin_user                 = lookup('profile::webperf::xhgui::mysql_admin_user'),
    String $xhgui_mysql_admin_password             = lookup('profile::webperf::xhgui::mysql_admin_password'),
    Stdlib::Fqdn $excimer_mysql_host               = lookup('profile::webperf::site::excimer_mysql_host'),
    String $excimer_mysql_db                       = lookup('profile::webperf::site::excimer_mysql_db'),
    String $excimer_mysql_user                     = lookup('profile::webperf::site::excimer_mysql_user'),
    String $excimer_mysql_password                 = lookup('profile::webperf::site::excimer_mysql_password'),
    Hash[String, Hash] $swift_accounts             = lookup('profile::swift::accounts'),
) {
    ensure_packages(['libapache2-mod-php', 'php-mbstring', 'php-mysql', 'mariadb-client'])

    $php_version = wmflib::debian_php_version()

    class { '::httpd':
        modules   => ["php${php_version}", 'rewrite', 'proxy', 'proxy_http', 'remoteip', 'headers', 'ssl'],
        http_only => true,
    }

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
    firewall::service { 'performance-website-global':
        proto    => 'tcp',
        port     => 80,
        src_sets => ['CACHES'],
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

    file { "/etc/php/${php_version}/apache2/conf.d/50-webperf.ini":
        ensure  => file,
        content => wmflib::php_ini({
            # XHGui requires more than the default 128M
            'memory_limit' => '512M',
        }),
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        notify  => Class['::httpd'],
    }

    $httpd_config = [
        'SetEnv EXCIMER_CONFIG_PATH /etc/excimer-ui-server/config.json',
        'SetEnv XHGUI_SAVE_HANDLER pdo',
        # Turn off schema mgmt, as the app fatals unconditionally otherwise.
        # We deploy XHGui as read-only frontend (enforced with non-admin DB grant).
        # https://github.com/perftools/xhgui/pull/494
        'SetEnv XHGUI_PDO_INITSCHEMA "false"',
        "SetEnv XHGUI_PDO_DSN \"mysql:host=${xhgui_mysql_host};dbname=${xhgui_mysql_db};charset=utf8\"",
        "SetEnv XHGUI_PDO_USER \"${xhgui_mysql_user}\"",
        "SetEnv XHGUI_PDO_PASS \"${xhgui_mysql_password}\"",
        'SetEnv XHGUI_PDO_TABLE xhgui'
    ];
    httpd::conf { 'webperf_env':
        content => inline_template("<%= @httpd_config.join(\"\n\") %>\n"),
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
