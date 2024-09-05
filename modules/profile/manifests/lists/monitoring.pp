# SPDX-License-Identifier: Apache-2.0
class profile::lists::monitoring (
    Stdlib::Fqdn $lists_servername = lookup('mailman::lists_servername'),
    Wmflib::Ensure $ensure         = lookup('mailman::include_monitoring', default_value => 'absent'),
    Stdlib::Unixpath $mailman_root = lookup('profile::lists::mailman_root', default_value => '/var/lib/mailman3')
) {
    monitoring::service { 'smtp':
        ensure        => $ensure,
        description   => 'Exim SMTP',
        check_command => 'check_smtp_tls_le',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Exim',
    }

    monitoring::service { 'https':
        ensure        => $ensure,
        description   => 'HTTPS',
        check_command => "check_ssl_http_letsencrypt!${lists_servername}",
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Mailman/Monitoring',
    }

    nrpe::monitor_service { 'mailman_queue':
        ensure       => $ensure,
        description  => 'mailman_queue_size',
        nrpe_command => '/usr/local/lib/nagios/plugins/check_mailman_queue 25 25 25',
        sudo_user    => 'list',
        notes_url    => 'https://wikitech.wikimedia.org/wiki/Mailman/Monitoring',
    }

    # mailman3 service
    nrpe::monitor_service { 'procs_mailman3':
        ensure       => $ensure,
        description  => 'mailman3',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -u list --ereg-argument-array=\'/mailman3/bin/master\'',
        notes_url    => 'https://wikitech.wikimedia.org/wiki/Mailman/Monitoring',
    }
    # uwsgi powering mailman3
    nrpe::monitor_service { 'procs_mailman3_web':
        ensure       => $ensure,
        description  => 'mailman3-web',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 5:5 -u www-data --ereg-argument-array=\'/usr/bin/uwsgi\'',
        notes_url    => 'https://wikitech.wikimedia.org/wiki/Mailman/Monitoring',
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
    }

    nrpe::monitor_service { 'mailman3_runners':
        ensure       => $ensure,
        description  => 'mailman3_runners',
        # As of Mailman Core 3.3.3, there are 14 runners
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 14: -u list --ereg-argument-array=\'/usr/lib/mailman3/bin/runner\'',
        notes_url    => 'https://wikitech.wikimedia.org/wiki/Mailman/Monitoring',
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
        ensure        => $ensure,
        description   => 'mailman list info',
        check_command => "check_https_url_for_string!${lists_servername}!/postorius/lists/wikimedia-l.lists.wikimedia.org/!Wikimedia Mailing List",
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Mailman/Monitoring',
    }

    monitoring::service { 'mailman_archives':
        ensure        => $ensure,
        description   => 'mailman archives',
        check_command => "check_https_url_for_string!${lists_servername}!/hyperkitty/list/wikimedia-l@lists.wikimedia.org/!Wikimedia Mailing List",
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Mailman/Monitoring',
    }

    monitoring::service { 'mailman_listinfo_ssl_expiry':
        ensure        => $ensure,
        description   => 'mailman list info ssl expiry',
        check_command => "check_https_expiry!${lists_servername}!443",
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Mailman/Monitoring',
    }

    monitoring::check_prometheus { 'mailman_hours_until_empty_outbound_queue':
        ensure          => $ensure,
        description     => 'Mailman outbound queue hours until empty.',
        dashboard_links => ['https://grafana.wikimedia.org/d/nULM0E1Wk/mailman'],
        query           => "node_files_total{instance=\"${::hostname}:9100\", path=~\"(.*)mailman/qfiles/out\"}/scalar(rate(mailman_smtp_duration_seconds{instance=\"${::hostname}:3903\"}[10m])/rate(mailman_smtp_total{instance=\"${::hostname}:3903\"}[10m]))/60",
        warning         => 2,  # this value should be tuned to above normal daily utilization. historically, a spike below this happens at 08:00 UTC each day
        critical        => 20, # this value should be tuned to handle abnormal daily utilization. historically, a spike below this happens at the first of each month.
        method          => 'ge',
        check_interval  => 60,
        retry_interval  => 2,
        nan_ok          => true,
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Mailman/Monitoring',
        prometheus_url  => "http://prometheus.svc.${::site}.wmnet/ops",
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
