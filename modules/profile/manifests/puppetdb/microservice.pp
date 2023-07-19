# SPDX-License-Identifier: Apache-2.0
#
class profile::puppetdb::microservice (
    Boolean             $enabled       = lookup('profile::puppetdb::microservice::enabled'),
    Stdlib::Port        $port          = lookup('profile::puppetdb::microservice::port'),
    Stdlib::Port        $uwsgi_port    = lookup('profile::puppetdb::microservice::uwsgi_port'),
    Array[Stdlib::Host] $allowed_hosts = lookup('profile::puppetdb::microservice::allowed_hosts'),
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
            hosts   => ['puppetdb-api.discovery.wmnet', 'puppetdb-api-next.discovery.wmnet'],
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

    if debian::codename::ge('bookworm') {
        # The microservice is managed via a dedicated systemd unit (uwsgi-puppetdb-microservice),
        # mask the generic uwsgi unit which gets auto-translated based on the init.d script
        # shipped in the uwsgi Debian package
        systemd::mask { 'mask_default_uwsgi_puppetdb':
            unit => 'uwsgi.service',
        }
    }

    profile::auto_restarts::service { 'uwsgi-puppetdb-microservice': }

    ferm::service { 'puppetdb-microservice':
        ensure => $ferm_ensure,
        proto  => 'tcp',
        port   => $port,
        srange => "@resolve((${allowed_hosts.join(' ')}))",
    }
}
