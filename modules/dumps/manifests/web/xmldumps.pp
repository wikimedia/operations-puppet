# serve xml/sql dumps: https://wikitech.wikimedia.org/wiki/Dumps
class dumps::web::xmldumps(
    $do_acme          = true,
    $datadir          = undef,
    $xmldumpsdir      = undef,
    $miscdatasetsdir  = undef,
    $htmldumps_server = undef,
    $xmldumps_server  = undef,
    $webuser          = undef,
    $webgroup         = undef,
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

    file { "${xmldumpsdir}/favicon.ico":
        source => 'puppet:///modules/dumps/web/xmldumps/favicon.ico',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }

    ferm::service { 'xmldumps_http':
        proto => 'tcp',
        port  => '80',
    }

    ferm::service { 'xmldumps_https':
        proto => 'tcp',
        port  => '443',
    }

    monitoring::service { 'http':
        description   => 'HTTP',
        check_command => 'check_http',
        contact_group => 'wmcs-team,admins',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Dumps/XML-SQL_Dumps#A_labstore_host_dies_(web_or_nfs_server_for_dumps)',
    }

    if ($do_acme == true) {
        monitoring::service { 'https':
            description   => 'HTTPS',
            check_command => "check_ssl_http_letsencrypt!${xmldumps_server}",
            contact_group => 'wmcs-team,admins',
            notes_url     => 'https://wikitech.wikimedia.org/wiki/Dumps/XML-SQL_Dumps#A_labstore_host_dies_(web_or_nfs_server_for_dumps)',
        }
    }
}
