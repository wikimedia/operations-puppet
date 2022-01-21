#
class profile::puppetdb::microservice (
    Boolean             $enabled          = lookup('profile::puppetdb::microservice::enabled'),
    Stdlib::Port        $port             = lookup('profile::puppetdb::microservice::port'),
    Stdlib::Port        $uwsgi_port       = lookup('profile::puppetdb::microservice::uwsgi_port'),
    Array[Stdlib::Host] $allowed_hosts    = lookup('profile::puppetdb::microservice::allowed_hosts'),
    Array[Stdlib::Host] $prometheus_nodes = lookup('prometheus_nodes'),
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

    ensure_packages(['python3-flask'])

    if $enabled {
        $certs = profile::pki::get_cert('discovery', $facts['networking']['fqdn'], {
            hosts   => ['puppetdb-api.discovery.wmnet'],
            notify  => Exec['nginx-reload'],
        })
        $site_content = template('profile/puppetdb/nginx-puppetdb-microservice.conf.erb')
    } else {
        $site_content = undef
    }

    nginx::site { 'puppetdb-microservice':
        ensure  => $ensure,
        content => $site_content,
    }

    file { '/srv/puppetdb-microservice.py':
        ensure => $ensure,
        source => 'puppet:///modules/profile/puppetdb/puppetdb-microservice.py',
        owner  => 'root',
        mode   => '0644',
        notify => Service['uwsgi-puppetdb-microservice'],
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

    # Network probes will be coming from Prometheus hosts
    $ferm_allow_hosts = $allowed_hosts + $prometheus_nodes

    ferm::service { 'puppetdb-microservice':
        ensure => $ferm_ensure,
        proto  => 'tcp',
        port   => $port,
        srange => "@resolve((${ferm_allow_hosts.join(' ')}))",
    }
}

