class profile::durum (
  Stdlib::Fqdn                $domain   = lookup('profile::durum::service::domain'),
  Profile::Durum::Service_ips $ips      = lookup('profile::durum::service::ips'),
  Profile::Durum::Common      $common   = lookup('profile::durum::service::common'),
) {

    $durum_path = $common['durum_path']

    $durum_file = "${durum_path}/${common['app_file']}"
    $template_file = "${durum_path}/templates/${common['template_file']}"

    ensure_packages(['python3-flask'])

    file { [$durum_path, "${durum_path}/templates"]:
        ensure => 'directory',
    }

    file {
        default:
            ensure  => 'present',
            owner   => 'www-data',
            group   => 'www-data',
            mode    => '0440',
            notify  => Service['uwsgi-durum'],
            require => Package['python3-flask'];
        $durum_file:
            content => template('profile/durum/durum.py.erb');
        $template_file:
            content => template('profile/durum/index.html.erb');
    }

    uwsgi::app { 'durum':
        settings => {
            uwsgi => {
                plugins   => 'python3',
                socket    => $common['sock_file'],
                wsgi-file => $durum_file,
                callable  => 'app',
            }
        },
        require  => [
          File[$durum_file],
          File[$template_file],
        ],
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
        require => Uwsgi::App['durum'],
    }

}
