class profile::durum (
  Stdlib::Fqdn                $domain   = lookup('profile::durum::service::domain'),
  Profile::Durum::Service_ips $ips      = lookup('profile::durum::service::ips'),
  Profile::Durum::Common      $common   = lookup('profile::durum::service::common'),
) {

    $durum_path = $common['durum_path']
    $index_file = "${durum_path}/index.html"
    $js_file = "${durum_path}/uuidv4.js"

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
        $js_file:
            content => file('profile/durum/uuidv4.js');
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
          File[$js_file],
        ]
    }

}
