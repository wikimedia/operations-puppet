class profile::lists::monitoring (
    Stdlib::Fqdn $lists_servername = lookup('mailman::lists_servername'),
    Optional[String] $standby_host = lookup('profile::lists::standby_host', {'default_value' => undef})
) {
    monitoring::service { 'smtp':
        description   => 'Exim SMTP',
        check_command => 'check_smtp_tls_le',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Exim',
    }

    monitoring::service { 'https':
        description   => 'HTTPS',
        check_command => "check_ssl_http_letsencrypt!${lists_servername}",
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Mailman/Monitoring',
    }

    # Don't monitor mailman processes on standby hosts. The mailman service is stopped there.
    if $facts['fqdn'] != $standby_host {

        nrpe::monitor_service { 'procs_mailmanctl':
            ensure       => absent,
            description  => 'mailman_ctl',
            nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -u list --ereg-argument-array=\'/mailman/bin/mailmanctl\'',
            notes_url    => 'https://wikitech.wikimedia.org/wiki/Mailman/Monitoring',
        }

        nrpe::monitor_service { 'procs_mailman_qrunner':
            ensure       => absent,
            description  => 'mailman_qrunner',
            nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 8:8 -u list --ereg-argument-array=\'/mailman/bin/qrunner\'',
            notes_url    => 'https://wikitech.wikimedia.org/wiki/Mailman/Monitoring',
        }

        nrpe::monitor_service { 'mailman_queue':
            description  => 'mailman_queue_size',
            nrpe_command => '/usr/local/lib/nagios/plugins/check_mailman_queue 25 25 25',
            sudo_user    => 'list',
            notes_url    => 'https://wikitech.wikimedia.org/wiki/Mailman/Monitoring',
        }

        sudo::user { 'nagios_mailman_queue':
            ensure => absent,
        }

        # mailman3 service
        nrpe::monitor_service { 'procs_mailman3':
            description  => 'mailman3',
            nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -u list --ereg-argument-array=\'/mailman3/bin/master\'',
            notes_url    => 'https://wikitech.wikimedia.org/wiki/Mailman/Monitoring',
        }
        # uwsgi powering mailman3
        nrpe::monitor_service { 'procs_mailman3_web':
            description  => 'mailman3-web',
            nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 2:2 -u www-data --ereg-argument-array=\'/usr/bin/uwsgi\'',
            notes_url    => 'https://wikitech.wikimedia.org/wiki/Mailman/Monitoring',
        }
        nrpe::monitor_service { 'mailman3_queue':
            description     => 'mailman3_queue_size',
            dashboard_links => ['https://grafana.wikimedia.org/d/GvuAmuuGk/mailman3'],
            nrpe_command    => '/usr/local/lib/nagios/plugins/check_mailman_queue --mailman3 25 25 25',
            sudo_user       => 'list',
            notes_url       => 'https://wikitech.wikimedia.org/wiki/Mailman/Monitoring',
            check_interval  => 5,
            retry_interval  => 5,
        }

        nrpe::monitor_service { 'mailman3_runners':
            description  => 'mailman3_runners',
            # As of Mailman Core 3.3.3, there are 14 runners
            nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 14:14 -u list --ereg-argument-array=\'/usr/lib/mailman3/bin/runner\'',
            notes_url    => 'https://wikitech.wikimedia.org/wiki/Mailman/Monitoring',
        }
        prometheus::node_file_count {'track mailman3 queue depths':
            paths   => [
                '/var/lib/mailman3/queue/in',
                '/var/lib/mailman3/queue/bounces',
                '/var/lib/mailman3/queue/virgin',
                '/var/lib/mailman3/queue/out',
            ],
            outfile => '/var/lib/prometheus/node.d/mailman3_queues.prom'
        }
    }

    monitoring::service { 'mailman_listinfo':
        description   => 'mailman list info',
        check_command => "check_https_url_for_string!${lists_servername}!/postorius/lists/wikimedia-l.lists.wikimedia.org/!Wikimedia Mailing List",
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Mailman/Monitoring',
    }

    monitoring::service { 'mailman_archives':
        description   => 'mailman archives',
        check_command => "check_https_url_for_string!${lists_servername}!/hyperkitty/list/wikimedia-l@lists.wikimedia.org/!Wikimedia Mailing List",
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Mailman/Monitoring',
    }

    monitoring::service { 'mailman_listinfo_ssl_expiry':
        description   => 'mailman list info ssl expiry',
        check_command => "check_https_expiry!${lists_servername}!443",
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Mailman/Monitoring',
    }

    monitoring::check_prometheus { 'mailman_hours_until_empty_outbound_queue':
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

    prometheus::node_file_count {'track mailman queue depths':
        ensure  => absent,
        paths   => [
            '/var/lib/mailman/qfiles/in',
            '/var/lib/mailman/qfiles/bounces',
            '/var/lib/mailman/qfiles/virgin',
            '/var/lib/mailman/qfiles/out',
        ],
        outfile => '/var/lib/prometheus/node.d/mailman_queues.prom'
    }

    nrpe::plugin { 'check_mailman_queue':
        source => 'puppet:///modules/icinga/check_mailman_queue.py',
    }

    # Mtail program to gather smtp send duration and count
    mtail::program { 'mailman':
        ensure => 'present',
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
        ensure => 'present',
        source => 'puppet:///modules/mtail/programs/exim.mtail',
        notify => Service['mtail'],
    }

    class { 'prometheus::node_exim_queue':
        ensure => present,
    }
}
