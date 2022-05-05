class profile::durum (
  Stdlib::Fqdn                $domain   = lookup('profile::durum::service::domain'),
  Profile::Durum::Service_ips $ips      = lookup('profile::durum::service::ips'),
  Profile::Durum::Common      $common   = lookup('profile::durum::service::common'),
) {

    $durum_path = $common['durum_path']

    $index_file = "${durum_path}/index.html"
    $uuid_js_file = "${durum_path}/uuidv4.js"
    $check_js_file = "${durum_path}/check.js"
    $css_file = "${durum_path}/site.css"

    motd::script { 'durum-motd':
        ensure   => 'present',
        priority => 1,
        content  => file('profile/durum/motd.sh'),
    }

    file { $durum_path:
        ensure => 'directory',
    }

    file {
        default:
            ensure => 'present',
            owner  => 'www-data',
            group  => 'www-data',
            mode   => '0440';
        $index_file:
            content => file('profile/durum/index.html');
        $uuid_js_file:
            content => file('profile/durum/uuidv4.js');
        $check_js_file:
            content => file('profile/durum/check.js');
        $css_file:
            content => file('profile/durum/site.css');
    }

    include network::constants
    ferm::service { 'durum-https':
        proto   => 'tcp',
        notrack => true,
        port    => 443,
    }

    acme_chief::cert { 'durum':
        puppet_svc => 'nginx',
    }

    class { 'sslcert::dhparam': }

    $ssl_settings = ssl_ciphersuite('nginx', 'strong', true)
    nginx::site { 'durum':
        content => template('profile/durum/nginx.conf.erb'),
        require => [
          File[$index_file],
          File[$uuid_js_file],
          File[$check_js_file],
          File[$css_file],
        ]
    }

    monitoring::service { 'check_durum_ipv4':
        description   => 'Wikidough durum Check (IPv4)',
        check_command => "check_tcp_ssl!${ips['landing'][0]}!443",
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Durum'
    }

    monitoring::service { 'check_durum_ipv6':
        description   => 'Wikidough durum Check (IPv6)',
        check_command => "check_tcp_ssl!${ips['landing'][1]}!443",
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Durum'
    }

}
