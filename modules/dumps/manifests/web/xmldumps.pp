# serve xml/sql dumps: https://wikitech.wikimedia.org/wiki/Dumps
class dumps::web::xmldumps (
    Stdlib::Fqdn               $web_hostname,
    Stdlib::Unixpath           $datadir,
    Stdlib::Unixpath           $xmldumpsdir,
    Stdlib::Unixpath           $miscdatasetsdir,
    String[1]                  $webuser,
    String[1]                  $webgroup,
    Array[Stdlib::IP::Address] $cache_hosts,
    String[1]                  $blocked_user_agent_regex,
    Array[Stdlib::IP::Address] $blocked_cidrs = [],
) {
    class {'dumps::web::html':
        datadir         => $datadir,
        xmldumpsdir     => $xmldumpsdir,
        miscdatasetsdir => $miscdatasetsdir,
        webuser         => $webuser,
        webgroup        => $webgroup,
    }

    $ssl_settings = ssl_ciphersuite('nginx', 'mid', true)

    acme_chief::cert { 'dumps':
        puppet_svc => 'nginx',
    }

    nginx::site { 'xmldumps':
        content => template('dumps/web/xmldumps/nginx.conf.erb'),
        notify  => Service['nginx'],
    }
    include dumps::web::nginx_logrot

    profile::auto_restarts::service { 'nginx': }

    file { "${xmldumpsdir}/favicon.ico":
        source => 'puppet:///modules/dumps/web/xmldumps/favicon.ico',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }

    prometheus::blackbox::check::http { $web_hostname:
        team               => 'wmcs',
        severity           => 'critical',
        body_regex_matches => ['Wikimedia Downloads'],
        probe_runbook      => 'https://wikitech.wikimedia.org/wiki/Dumps/SQL-XML_Dumps#NFS_share_and/or_web_server_issues',
    }
}
