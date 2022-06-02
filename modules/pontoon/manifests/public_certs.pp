# SPDX-License-Identifier: Apache-2.0
# Acquire letsencrypt certs for services with public endpoints.
# For simplicity reasons certbot's webroot authenticator and apache are used.
# The tradeoff being only one host running this class (i.e. the frontend
# LB) is possible (certs are not distributed to multiple frontend hosts)

class pontoon::public_certs (
  Hash[String, Wmflib::Service] $services_config,
  String $public_domain,
) {
    ensure_packages('certbot')

    $public_names = $services_config.reduce([]) |$memo, $el| {
        [$service_name, $config] = $el

        if 'public_aliases' in $config {
            $aliases = $config['public_aliases'].map |$a| { "${a}.${public_domain}" }
        } else {
            $aliases = []
        }

        $memo + $aliases + "${config['public_endpoint']}.${public_domain}"
    }

    file { '/etc/apache2/sites-enabled/000-default.conf':
        source => 'puppet:///modules/pontoon/public-certs-httpd.conf',
        mode   => '0444',
        owner  => 'root',
        group  => 'root',
        notify => Service['apache2'],
    }

    file { '/etc/letsencrypt/cli.ini':
        content => template('pontoon/certbot.ini.erb'),
        notify  => Exec['certbot-certonly'],
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
    }

    file { '/etc/letsencrypt/renewal-hooks/deploy/pontoon-public-certs.sh':
        source => 'puppet:///modules/pontoon/certbot-deploy.sh',
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
    }

    exec { 'certbot-certonly':
        refreshonly => true,
        command     => '/usr/bin/certbot certonly',
    }
}
