# SPDX-License-Identifier: Apache-2.0
# Installs a web server for "light" install_servers without APT
class profile::installserver::http_light {

    file { '/etc/nginx/nginx.conf':
        content => template('install_server/nginx.conf.erb'),
        tag     => 'nginx',
    }

    nginx::site { 'install.wikimedia.org':
        content => template('install_server/install.wikimedia.org.conf.erb'),
    }

    profile::auto_restarts::service { 'nginx': }

    # prevent a /srv root autoindex; empty for now.
    file { '/srv/index.html':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => '',
    }

    ferm::service { 'install_http_light':
        proto  => 'tcp',
        port   => '80',
        srange => '$DOMAIN_NETWORKS',
    }

    monitoring::service { 'http':
        description   => 'HTTP',
        check_command => 'check_http',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Install_servers',
    }
}
