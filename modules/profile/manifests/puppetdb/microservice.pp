# SPDX-License-Identifier: Apache-2.0
# @summary install the puppetdb micro service
# @param enabled wether to enable the service
# @param port the port to listen on
# @param uwsgi_port the port of the backend service
# @param allowed_hosts a list of allowed hosts
# @param allowed_roles a list of allowed roles
class profile::puppetdb::microservice (
    Boolean             $enabled       = lookup('profile::puppetdb::microservice::enabled'),
    Stdlib::Port        $port          = lookup('profile::puppetdb::microservice::port'),
    Stdlib::Port        $uwsgi_port    = lookup('profile::puppetdb::microservice::uwsgi_port'),
    Array[Stdlib::Host] $allowed_hosts = lookup('profile::puppetdb::microservice::allowed_hosts'),
    Array[String[1]]    $allowed_roles = lookup('profile::puppetdb::microservice::allowed_roles'),
) {
    $ssl_settings = ssl_ciphersuite('nginx', 'strong', true)
    $_allowed_hosts = $allowed_roles.map |$role| {
        wmflib::role::ips($role)
    }.flatten + $allowed_hosts

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
        ensure  => stdlib::ensure($enabled),
        content => $site_content,
    }

    file { '/srv/puppetdb-microservice.py':
        ensure => stdlib::ensure($enabled, 'file'),
        source => 'puppet:///modules/profile/puppetdb/puppetdb-microservice.py',
        owner  => 'root',
        mode   => '0644',
        notify => Service['uwsgi-puppetdb-microservice'],
    }
    uwsgi::app { 'puppetdb-microservice':
        ensure     => stdlib::ensure($enabled),
        monitoring => absent,
        settings   => {
            uwsgi => {
                'plugins'     => 'python3',
                'socket'      => '/run/uwsgi/puppetdb-microservice.sock',
                'file'        => '/srv/puppetdb-microservice.py',
                'callable'    => 'app',
                'http-socket' => "127.0.0.1:${uwsgi_port}",
            },
        },
    }

    # The microservice is managed via a dedicated systemd unit (uwsgi-puppetdb-microservice),
    # mask the generic uwsgi unit which gets auto-translated based on the init.d script
    # shipped in the uwsgi Debian package
    systemd::mask { 'mask_default_uwsgi_puppetdb':
        unit => 'uwsgi.service',
    }

    profile::auto_restarts::service { 'uwsgi-puppetdb-microservice':
        ensure => stdlib::ensure($enabled),
    }

    unless $_allowed_hosts.empty() {
        firewall::service { 'puppetdb-microservice':
            proto  => 'tcp',
            port   => $port,
            srange => $_allowed_hosts,
        }
    }
}
