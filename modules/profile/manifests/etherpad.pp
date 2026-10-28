# SPDX-License-Identifier: Apache-2.0
# sets up an Etherpad lite server
class profile::etherpad(
    Stdlib::IP::Address $listen_ip = lookup('profile::etherpad::listen_ip'),
    Stdlib::Ensure::Service $service_ensure = lookup('profile::etherpad::service_ensure'),
    Stdlib::Unixpath $database_datadir = lookup('profile::etherpad::database_datadir', {default_value => '/var/lib/mysql'}),
){

    include ::passwords::etherpad_lite

    class { '::etherpad':
        etherpad_db_user => $passwords::etherpad_lite::etherpad_db_user,
        etherpad_db_host => $passwords::etherpad_lite::etherpad_db_host,
        etherpad_db_name => $passwords::etherpad_lite::etherpad_db_name,
        etherpad_db_pass => $passwords::etherpad_lite::etherpad_db_pass,
        etherpad_ip      => $listen_ip,
        service_ensure   => $service_ensure,
    }

    class { '::profile::prometheus::etherpad_exporter':
        service_ensure => $service_ensure,
        listen_ip      => $facts['networking']['ip'],
        require        => Class['::etherpad'],
    }

    if $service_ensure == running {

        prometheus::blackbox::check::http { 'etherpad-envoy':
            server_name        => 'etherpad.wikimedia.org',
            team               => 'collaboration-services',
            severity           => 'task',
            path               => '/',
            ip_families        => ['ip4'],
            port               => 7443,
            force_tls          => true,
            body_regex_matches => ['Pad'],
        }

        prometheus::blackbox::check::http { 'etherpad-nodejs':
            server_name        => 'etherpad.wikimedia.org',
            team               => 'collaboration-services',
            severity           => 'task',
            path               => '/',
            ip_families        => ['ip6'],
            port               => 9001,
            force_tls          => false,
            body_regex_matches => ['Pad'],
        }
    }

    # While etherpad is stopped, serve a static page on its port instead.
    # envoy keeps forwarding to port 9001, so envoy and ATS need no changes.
    if $service_ensure == 'stopped' {
        class { 'httpd':
            modules              => ['rewrite'],
            remove_default_ports => true,
        }

        # /var/www is created by the apache2 package
        file { '/var/www/etherpad-offline':
            ensure  => directory,
            require => Class['httpd'],
        }

        file { '/var/www/etherpad-offline/index.html':
            source => 'puppet:///modules/profile/etherpad/offline.html',
        }

        # every path, including old /p/<pad> links, gets the page
        httpd::site { 'etherpad-offline':
            require => Class['etherpad'],
            content => @(CONF),
                Listen 9001
                <VirtualHost *:9001>
                    DocumentRoot /var/www/etherpad-offline
                    RewriteEngine On
                    RewriteRule ^ /index.html [L]
                </VirtualHost>
                | CONF
        }
    } else {
        # stop the offline page again, etherpad needs port 9001
        service { 'apache2':
            ensure => stopped,
            enable => false,
            before => Service['etherpad-lite'],
        }
    }

    firewall::service { 'etherpad_service':
        proto    => 'tcp',
        port     => 9001,
        src_sets => ['CACHES'],
    }

    profile::auto_restarts::service { 'envoyproxy': }

    # Ship etherpad server logs to ELK using startmsg_regex pattern to join multi-line events based on datestamp
    # example: [2018-11-30 21:32:43.412]
    rsyslog::input::file { 'etherpad-multiline':
        path           => '/var/log/etherpad-lite/etherpad-lite.log',
        startmsg_regex => '^\\\\[[0-9,-\\\\ \\\\:]+\\\\]',
    }

    # in cloud, use a local db server
    if $::realm == 'labs' {
        class { 'profile::mariadb::generic_server':
            datadir => $database_datadir,
        }
    }
}
