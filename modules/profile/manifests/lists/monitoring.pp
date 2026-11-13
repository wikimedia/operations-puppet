# SPDX-License-Identifier: Apache-2.0
# @param uwsgi_processes number of uwsgi worker processes to handle requests
class profile::lists::monitoring (
    Stdlib::Fqdn $lists_servername = lookup('mailman::lists_servername'),
    Wmflib::Ensure $ensure         = lookup('mailman::include_monitoring', default_value => 'absent'),
    Stdlib::Unixpath $mailman_root = lookup('profile::lists::mailman_root', default_value => '/var/lib/mailman3'),
    Integer $uwsgi_processes       = lookup('profile::lists::uwsgi_processes', {'default_value' => 4}),
) {
    # Probe the web UI through envoy on the active host, the same path as
    # the CDN. The ATS backend alerts need more traffic per site than lists
    # gets, so they do not fire.
    if $ensure == 'present' {
        prometheus::blackbox::check::http { $lists_servername:
            port               => 8443,
            force_tls          => true,
            # envoy listens on IPv4 only (listen_ipv6 is false).
            ip_families        => ['ip4'],
            path               => '/postorius/lists/wikimedia-l.lists.wikimedia.org/',
            body_regex_matches => ['Wikimedia Mailing List'],
            timeout            => '10s',
            team               => 'collaboration-services',
            severity           => 'task',
            probe_runbook      => 'https://wikitech.wikimedia.org/wiki/Mailman/Monitoring',
        }
    }

    monitoring::service { 'smtp':
        ensure         => $ensure,
        description    => 'Exim SMTP',
        check_command  => 'check_smtp_tls_le',
        notes_url      => 'https://wikitech.wikimedia.org/wiki/Exim',
        migration_task => 'T370157',
    }

    monitoring::service { 'https':
        ensure         => $ensure,
        description    => 'HTTPS',
        check_command  => "check_ssl_http_letsencrypt!${lists_servername}",
        notes_url      => 'https://wikitech.wikimedia.org/wiki/Mailman/Monitoring',
        migration_task => 'T370157',
    }

    nrpe::monitor_service { 'mailman_queue':
        ensure         => $ensure,
        description    => 'mailman_queue_size',
        nrpe_command   => '/usr/local/lib/nagios/plugins/check_mailman_queue 25 25 25',
        sudo_user      => 'list',
        notes_url      => 'https://wikitech.wikimedia.org/wiki/Mailman/Monitoring',
        migration_task => 'T370157',
    }

    # uwsgi powering mailman3
    # uwsgi master process + configured worker processes
    $uwsgi_expected_processes = $uwsgi_processes + 1

    nrpe::monitor_service { 'procs_mailman3_web':
        ensure         => $ensure,
        description    => 'mailman3-web',
        nrpe_command   => "/usr/lib/nagios/plugins/check_procs -c ${uwsgi_expected_processes}:${uwsgi_expected_processes} -u www-data --ereg-argument-array='/usr/bin/uwsgi'",
        notes_url      => 'https://wikitech.wikimedia.org/wiki/Mailman/Monitoring',
        migration_task => 'T357099',
    }
    nrpe::monitor_service { 'mailman3_queue':
        ensure          => $ensure,
        description     => 'mailman3_queue_size',
        dashboard_links => ['https://grafana.wikimedia.org/d/GvuAmuuGk/mailman3'],
        nrpe_command    => '/usr/local/lib/nagios/plugins/check_mailman_queue --mailman3 25 25 25',
        sudo_user       => 'list',
        notes_url       => 'https://wikitech.wikimedia.org/wiki/Mailman/Monitoring',
        check_interval  => 5,
        retry_interval  => 5,
        migration_task  => 'T370157',
    }

    nrpe::monitor_service { 'mailman3_runners':
        ensure         => $ensure,
        description    => 'mailman3_runners',
        # As of Mailman Core 3.3.3, there are 14 runners
        nrpe_command   => '/usr/lib/nagios/plugins/check_procs -c 14: -u list --ereg-argument-array=\'/usr/lib/mailman3/bin/runner\'',
        notes_url      => 'https://wikitech.wikimedia.org/wiki/Mailman/Monitoring',
        migration_task => 'T370157',
    }
    prometheus::node_file_count { 'track mailman3 queue depths':
        ensure  => $ensure,
        paths   => [
            "${$mailman_root}/queue/in",
            "${$mailman_root}/queue/bounces",
            "${$mailman_root}/queue/virgin",
            "${$mailman_root}/queue/out",
        ],
        outfile => '/var/lib/prometheus/node.d/mailman3_queues.prom'
    }

    monitoring::service { 'mailman_listinfo':
        ensure         => $ensure,
        description    => 'mailman list info',
        check_command  => "check_https_url_for_string!${lists_servername}!/postorius/lists/wikimedia-l.lists.wikimedia.org/!Wikimedia Mailing List",
        notes_url      => 'https://wikitech.wikimedia.org/wiki/Mailman/Monitoring',
        migration_task => 'T370157',
        check_interval => 5,
        retry_interval => 5,
    }

    monitoring::service { 'mailman_archives':
        ensure         => $ensure,
        description    => 'mailman archives',
        check_command  => "check_https_url_for_string!${lists_servername}!/hyperkitty/list/wikimedia-l@lists.wikimedia.org/!Wikimedia Mailing List",
        notes_url      => 'https://wikitech.wikimedia.org/wiki/Mailman/Monitoring',
        migration_task => 'T370157',
        check_interval => 5,
        retry_interval => 5,
    }

    monitoring::service { 'mailman_listinfo_ssl_expiry':
        ensure         => $ensure,
        description    => 'mailman list info ssl expiry',
        check_command  => "check_https_expiry!${lists_servername}!443",
        notes_url      => 'https://wikitech.wikimedia.org/wiki/Mailman/Monitoring',
        migration_task => 'T370157',
    }

    # The daily digest run at 08:00 UTC fills the queue for about 15 minutes,
    # so the check uses the smallest queue size over 30 minutes.
    # scalar() turns a missing series into NaN, which the check reports as UNKNOWN.
    monitoring::check_prometheus { 'mailman_outbound_queue_backlog':
        ensure          => $ensure,
        description     => 'Mailman outbound queue backlog (smallest size over 30 minutes)',
        dashboard_links => ['https://grafana.wikimedia.org/d/GvuAmuuGk/mailman3'],
        query           => "scalar(min_over_time(node_files_total{instance=\"${facts['networking']['hostname']}:9100\", path=\"${mailman_root}/queue/out\"}[30m]))",
        warning         => 25,
        critical        => 100,
        method          => 'ge',
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Mailman/Monitoring',
        prometheus_url  => "http://prometheus.svc.${::site}.wmnet/ops",
        migration_task  => 'T370157',
    }

    nrpe::plugin { 'check_mailman_queue':
        ensure => $ensure,
        source => 'puppet:///modules/icinga/check_mailman_queue.py',
    }

    # Mtail program to gather smtp send duration and count
    mtail::program { 'mailman':
        ensure => $ensure,
        source => 'puppet:///modules/mtail/programs/mailman.mtail',
        notify => Service['mtail'],
    }

    user { 'mtail':
        ensure  => 'present',
        groups  => ['list'],
        require => Package['mailman3']
    }

    # Mtail program to gather exim logs
    mtail::program { 'exim':
        ensure => $ensure,
        source => 'puppet:///modules/mtail/programs/exim.mtail',
        notify => Service['mtail'],
    }

    class { 'prometheus::node_exim_queue':
        ensure => $ensure,
    }
}
