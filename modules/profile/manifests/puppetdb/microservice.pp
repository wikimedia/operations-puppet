#
class profile::puppetdb::microservice (
    Boolean             $enabled       = lookup('profile::puppetdb::microservice::enabled'),
    Stdlib::Port        $port          = lookup('profile::puppetdb::microservice::port'),
    Stdlib::Port        $uwsgi_port    = lookup('profile::puppetdb::microservice::uwsgi_port'),
    Array[Stdlib::Host] $allowed_hosts = lookup('profile::netbox::frontends'),
) {
    $ssl_settings = ssl_ciphersuite('nginx', 'strong', true)
    $ensure = $enabled ? {
        false => 'absent',
        default => 'present',
    }
    $ferm_ensure = $allowed_hosts.empty? {
        false   => 'present',
        default => 'absent',
    }

    ensure_packages(['python3-flask'], {'ensure' => $ensure})

    nginx::site { 'puppetdb-microservice':
        ensure  => $ensure,
        content => template('profile/puppetdb/nginx-puppetdb-microservice.conf.erb'),
    }

    file { '/srv/puppetdb-microservice.py':
        ensure => $ensure,
        source => 'puppet:///modules/profile/puppetdb/puppetdb-microservice.py',
        owner  => 'root',
        mode   => '0644',
    }
    uwsgi::app { 'puppetdb-microservice':
        ensure   => $ensure,
        settings => {
            uwsgi => {
                'plugins'     => 'python3',
                'socket'      => '/run/uwsgi/puppetdb-microservice.sock',
                'file'        => '/srv/puppetdb-microservice.py',
                'callable'    => 'app',
                'http-socket' => "127.0.0.1:${uwsgi_port}",
            },
        },
    }
    ferm::service { 'puppetdb-microservice':
        ensure => $ferm_ensure,
        proto  => 'tcp',
        port   => $port,
        srange => "@resolve((${allowed_hosts.join(' ')}))",
    }
}

