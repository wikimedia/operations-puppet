# SPDX-License-Identifier: Apache-2.0
# vim: set ts=4 et sw=4:
# sets up an instance of the 'Volunteer Response Team System'
# https://wikitech.wikimedia.org/wiki/VRT_System
class profile::vrts(
    Stdlib::Fqdn $active_host        = lookup('profile::vrts::active_host'),
    Stdlib::Fqdn $passive_host       = lookup('profile::vrts::passive_host'),
    Stdlib::Fqdn $vrts_database_host = lookup('profile::vrts::database_host'),
    String $vrts_database_name       = lookup('profile::vrts::database_name'),
    String $vrts_database_user       = lookup('profile::vrts::database_user'),
    String $vrts_database_pw         = lookup('profile::vrts::database_pass'),
    String $vrts_database_port       = lookup('profile::vrts::database_port'),
    String $exim_database_name       = lookup('profile::vrts::exim_database_name'),
    String $exim_database_user       = lookup('profile::vrts::exim_database_user'),
    String $exim_database_pass       = lookup('profile::vrts::exim_database_pass'),
    String $download_url             = lookup('profile::vrts::download_url'),
    String $http_proxy               = lookup('profile::vrts::http_proxy'),
    String $https_proxy              = lookup('profile::vrts::https_proxy'),
    String $dns_name                 = lookup('profile::vrts::public_dns'),
    Boolean $local_database          = lookup('profile::vrts::local_database', {default_value => false}),
    Stdlib::Unixpath $db_datadir     = lookup('profile::vrts::db_datadir', {default_value => '/var/lib/mysql'}),
    String $start_date               = lookup('profile::vrts::sql_exporter_start_date'),
    Optional[
        Array[Stdlib::Fqdn]
    ] $mx_in_hosts                   = lookup('profile::vrts::mx_in_hosts', { 'default_value' => undef }),
){
    include network::constants
    include ::profile::prometheus::apache_exporter
    include profile::mail::default_mail_relay

    if $local_database {
        class { 'profile::mariadb::generic_server':
            datadir => $db_datadir,
        }
    }

    $trusted_networks = $network::constants::aggregate_networks.filter |$x| {
        $x !~ /127.0.0.0|::1/
    }

    $enable_service = $active_host == $facts['fqdn']

    class { '::vrts':
        vrts_database_host => $vrts_database_host,
        active_host        => $active_host,
        passive_host       => $passive_host,
        vrts_database_name => $vrts_database_name,
        vrts_database_user => $vrts_database_user,
        vrts_database_pw   => $vrts_database_pw,
        vrts_database_port => $vrts_database_port,
        vrts_daemon        => $enable_service,
        exim_database_name => $exim_database_name,
        exim_database_user => $exim_database_user,
        exim_database_pass => $exim_database_pass,
        trusted_networks   => $trusted_networks,
        download_url       => $download_url,
        http_proxy         => $http_proxy,
        https_proxy        => $https_proxy,
        public_dns         => $dns_name,
        mail_smarthosts    => $profile::mail::default_mail_relay::smarthosts,
    }

    class { 'prometheus::sql_exporter':
        db_connection   => "mysql://${vrts_database_user}:${vrts_database_pw}@tcp(${vrts_database_host})/${vrts_database_name}",
        job_name        => 'vrts_sql_metrics',
        scrape_interval => '30m',
        metrics         => {
            'valid_queues'         => {
                'name'    => 'vrts_queue_validity',
                'columns' => ['count'],
                'labels'  => ['name'],
                'query'   => @(QUERY/)
                            SELECT CAST(COUNT(*) AS DECIMAL) AS count, v.name AS name
                            FROM queue q INNER JOIN valid v ON q.valid_id = v.id
                            WHERE q.valid_id = 1;
                            | QUERY
            },
            'invalid_queues'       => {
                'name'    => 'vrts_queue_validity',
                'columns' => ['count'],
                'labels'  => ['name'],
                'query'   => @(QUERY/)
                            SELECT CAST(COUNT(*) AS DECIMAL) AS count, v.name AS name
                            FROM queue q INNER JOIN valid v ON q.valid_id = v.id
                            WHERE q.valid_id = 2;
                            | QUERY
            },
            'info_ticket_count'    => {
                'name'    => 'vrts_ticket_count',
                'columns' => ['count'],
                'labels'  => ['name'],
                'query'   => @("QUERY"/)
                            SELECT COUNT(t.id) AS count, 'info_queues' AS name FROM ticket t
                            INNER JOIN queue q ON t.queue_id = q.id
                            WHERE q.valid_id=1 AND q.name LIKE 'info%' AND t.create_time >= ${start_date};
                            | QUERY
            },
            'chapter_ticket_count' => {
                'name'    => 'vrts_ticket_count',
                'columns' => ['count'],
                'labels'  => ['name'],
                'query'   => @("QUERY"/)
                            SELECT COUNT(t.id) AS count, 'chapter_queues' AS name FROM ticket t
                            INNER JOIN queue q ON t.queue_id = q.id
                            WHERE q.valid_id=1 AND q.name LIKE 'chapter%' AND t.create_time >= ${start_date};
                            | QUERY
            }
        },

    }

    class { '::httpd':
        modules => ['headers', 'rewrite', 'perl'],
    }

    profile::auto_restarts::service { 'apache2': }
    profile::auto_restarts::service { 'envoyproxy': }

    # TODO: On purpose here since it references a file not in a module which is
    # used by other classes as well
    # lint:ignore:puppet_url_without_modules
    file { '/etc/exim4/wikimedia_domains':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///modules/role/exim/wikimedia_domains',
        require => Class['exim4'],
    }
    # lint:endignore

    firewall::service { 'vrts_http':
        proto    => 'tcp',
        port     => 80,
        src_sets => ['CACHES'],
    }

    # Receive mail from inbound mail hosts
    if $mx_in_hosts == undef {
        $_mx_in_hosts = profile::postfix::mx_inbound_hosts()
    } else {
        $_mx_in_hosts = $mx_in_hosts
    }
    firewall::service { 'vrts_smtp':
        proto  => 'tcp',
        port   => 25,
        srange => $_mx_in_hosts,
    }

    prometheus::blackbox::check::tcp { 'vrts-smtp':
        team     => 'collaboration-services',
        severity => 'task',
        port     => 25,
    }

    nrpe::monitor_service{ 'clamd':
        description  => 'clamd running',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -w 1:1 -c 1:1 -u clamav -C clamd',
        notes_url    => 'https://wikitech.wikimedia.org/wiki/VRT_System#ClamAV',
    }
    nrpe::monitor_service{ 'freshclam':
        description  => 'freshclam running',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -w 1:1 -c 1:1 -u clamav -C freshclam',
        notes_url    => 'https://wikitech.wikimedia.org/wiki/VRT_System#ClamAV',
    }

    if $active_host == $facts['fqdn'] {
        prometheus::blackbox::check::http { $dns_name:
            team               => 'collaboration-services',
            severity           => 'task',
            path               => '/otrs/index.pl',
            port               => 1443,
            ip_families        => ['ip4'],
            force_tls          => true,
            body_regex_matches => ['wikimedia'],
        }
    }

    # can conflict with ferm module
    ensure_packages('libnet-dns-perl')
}
