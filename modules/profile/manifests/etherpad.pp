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

    # insert a warning message into the index page (T420793)
    $warning_html = @(HTML)
                 Welcome to the <a href="https://meta.wikimedia.org/wiki/Etherpad">WMF Etherpad</a> installation. Please do NOT use it for personal use.<br />
                 <b>The Wikimedia Etherpad instance will be reset at the end of May 2026 per <a href="https://phabricator.wikimedia.org/T415237">T415237</a>.</b><br />
                 Please keep a copy of important data somewhere else and keep in mind all current as well as past content in any pad is public.<br />
    | HTML

    file_line { 'etherpad_index_warning':
        path   => '/usr/share/etherpad-lite/src/templates/index.html',
        line   => $warning_html,
        after  => '<div id="inner">',
        notify => Service['etherpad-lite'],
    }

    # in cloud, use a local db server
    if $::realm == 'labs' {
        class { 'profile::mariadb::generic_server':
            datadir => $database_datadir,
        }
    }
}
