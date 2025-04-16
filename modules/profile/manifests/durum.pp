# SPDX-License-Identifier: Apache-2.0
class profile::durum (
  Stdlib::Fqdn                $domain        = lookup('profile::durum::service::domain'),
  Profile::Durum::Service_ips $ips           = lookup('profile::durum::service::ips'),
  Profile::Durum::Common      $common        = lookup('profile::durum::service::common'),
  Stdlib::Unixpath            $ech_key_dir   = lookup('profile::durum::ech_key_dir'),
  Boolean                     $do_ech        = lookup('profile::durum::do_ech', { 'default_value' => false }),
  String                      $ech_outer_sni = lookup('profile::durum::ech_outer_sni', { 'default_value' => 'wikimedia-ech.org' }),
) {

    file { $ech_key_dir:
        ensure => $do_ech.bool2str('directory', 'absent'),
        owner  => 'root',
        group  => 'root',
        mode   => '0750',
    }
    file { "${ech_key_dir}/outer-ech.pem":
        ensure    => $do_ech.bool2str('present', 'absent'),
        owner     => 'root',
        group     => 'root',
        mode      => '0640',
        show_diff => false,
        backup    => false,
        content   => secret('keyholder/ech-durum.pem'),
    }
    # Set up a conf.d override for the http{} directive.
    file { '/etc/nginx/conf.d/nginx-http-override.conf':
        ensure  => $do_ech.bool2str('present', 'absent'),
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template('profile/durum/nginx-http-override.conf.erb'),
        notify  => Exec['nginx-reload'],
    }

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
        puppet_rsc => Exec['nginx-reload'],
    }

    class { 'sslcert::dhparam': }
    # Encrypted Client Hello experiment. T205378.
    # If enabled, install the nginx version with ECH support from component.
    if $do_ech {
        apt::package_from_component { 'nginx':
          component => 'component/nginx-ech',
        }
        acme_chief::cert { 'ech':
            puppet_rsc => Exec['nginx-reload'],
        }
    }

    $ssl_settings = ssl_ciphersuite('nginx', 'strong', true)
    nginx::site { 'durum':
        content => template('profile/durum/nginx.conf.erb'),
        require => [
          File[$index_file, $uuid_js_file, $check_js_file, $css_file],
        ]
    }

    profile::auto_restarts::service { 'nginx':}
}
