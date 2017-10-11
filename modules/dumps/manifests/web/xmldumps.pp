# serve xml/sql dumps: https://wikitech.wikimedia.org/wiki/Dumps
class dumps::web::xmldumps(
    $do_acme = true,
    $datadir = undef,
    $publicdir = undef,
    $otherdir = undef,
    $htmldumps_server = undef,
    $xmldumps_server = undef,
) {

    class {'dumps::web::html':
        datadir   => $datadir,
        publicdir => $publicdir,
        otherdir  => $otherdir,
    }

    class { '::nginx':
        variant => 'extras',
    }

    $ssl_settings = ssl_ciphersuite('nginx', 'mid', true)

    letsencrypt::cert::integrated { 'dumps':
        subjects   => $xmldumps_server,
        puppet_svc => 'nginx',
        system_svc => 'nginx',
    }

    nginx::site { 'xmldumps':
        content => template('dumps/web/xmldumps/nginx.conf.erb'),
        notify  => Service['nginx'],
    }
    include dumps::web::nginx_logrot

    file { "${publicdir}/favicon.ico":
        source => 'puppet:///modules/dumps/web/xmldumps/favicon.ico',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }

    include ::profile::base::firewall

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
        check_command => 'check_http'
    }

    if ($do_acme == true) {
        monitoring::service { 'https':
            description   => 'HTTPS',
            check_command => "check_ssl_http_letsencrypt!${xmldumps_server}",
        }
    }
}
