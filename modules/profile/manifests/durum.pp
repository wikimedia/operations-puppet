class profile::durum (
  Stdlib::Fqdn                $domain   = lookup('profile::durum::service::domain'),
  Profile::Durum::Service_ips $ips      = lookup('profile::durum::service::ips'),
  Profile::Durum::Common      $common   = lookup('profile::durum::service::common'),
  Profile::Durum::Messages    $messages = lookup('profile::durum::service::messages'),
) {

    $durum_file = $common['app_path']

    ensure_packages(['python3-flask'])

    file { $common['durum_path']:
        ensure => 'directory',
    }

    file { $durum_file:
        ensure  => 'present',
        owner   => 'www-data',
        group   => 'www-data',
        mode    => '0440',
        content => template('profile/durum/durum.py.erb'),
        require => [
          Package['python3-flask'],
        ],
    }

    uwsgi::app { 'durum':
        settings => {
            uwsgi => {
                plugins   => 'python3',
                socket    => $common['sock_path'],
                wsgi-file => $durum_file,
                callable  => 'app',
            }
        },
        require  => File[$durum_file],
    }

    include ::network::constants
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
