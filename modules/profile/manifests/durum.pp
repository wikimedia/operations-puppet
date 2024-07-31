# SPDX-License-Identifier: Apache-2.0
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
    firewall::service { 'durum-https':
        proto   => 'tcp',
        notrack => true,
        port    => [443],
    }

    acme_chief::cert { 'durum':
        puppet_svc => 'nginx',
    }

    class { 'sslcert::dhparam': }

    $ssl_settings = ssl_ciphersuite('nginx', 'strong', true)
    nginx::site { 'durum':
        content => template('profile/durum/nginx.conf.erb'),
        require => [
          File[$index_file, $uuid_js_file, $check_js_file, $css_file],
          Acme_chief::Cert['durum'],
        ]
    }

    profile::auto_restarts::service { 'nginx':}
}
