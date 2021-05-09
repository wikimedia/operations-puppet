class profile::mailman3 (
    Stdlib::Fqdn $host = lookup('profile::mailman3::host'),
    Stdlib::Fqdn $db_host = lookup('profile::mailman3::db_host'),
    String $db_name = lookup('profile::mailman3::db_name'),
    String $db_user = lookup('profile::mailman3::db_user'),
    String $db_password = lookup('profile::mailman3::db_password'),
    String $webdb_name = lookup('profile::mailman3::web::db_name'),
    String $webdb_user = lookup('profile::mailman3::web::db_user'),
    String $webdb_password = lookup('profile::mailman3::web::db_password'),
    String $api_password = lookup('profile::mailman3::api_password'),
    String $web_secret = lookup('profile::mailman3::web::secret'),
    String $archiver_key = lookup('profile::mailman3::archiver_key'),
    Optional[Stdlib::IP::Address::V4] $lists_ipv4 = lookup('profile::mailman3::ipv4', {'default_value' => undef}),
    Optional[Stdlib::IP::Address::V6] $lists_ipv6 = lookup('profile::mailman3::ipv6', {'default_value' => undef}),
    Optional[String] $acme_chief_cert = lookup('profile::mailman3::acme_chief_cert', {'default_value' => undef}),
    Optional[Stdlib::Fqdn] $mailman2_host = lookup('profile::mailman3::mailman2_host', {'default_value' => undef})
) {
    include network::constants

    class { '::mailman3':
        host           => $host,
        db_host        => $db_host,
        db_name        => $db_name,
        db_user        => $db_user,
        db_password    => $db_password,
        webdb_name     => $webdb_name,
        webdb_user     => $webdb_user,
        webdb_password => $webdb_password,
        api_password   => $api_password,
        archiver_key   => $archiver_key,
        web_secret     => $web_secret,
    }

    class { '::httpd':
        modules => ['rewrite', 'ssl', 'proxy', 'proxy_http', 'proxy_uwsgi', 'headers'],
    }

    $ssl_settings = ssl_ciphersuite('apache', 'mid', true)
    httpd::site { $host:
        content => template('mailman3/apache.conf.erb'),
    }

    if $acme_chief_cert {
        class { 'sslcert::dhparam': }
        acme_chief::cert{ $acme_chief_cert:
            puppet_svc => 'apache2',
            key_group  => 'Debian-exim',
        }
    }

    if $::realm == 'production' {
        # Make sure prod root@ (cronspam, etc.) goes to proper root alias
        mailalias { 'root': recipient => 'root@wikimedia.org' }
    }

    # This will be a noop if $lists_ipv[46] are undef
    interface::alias { $host:
        ipv4 => $lists_ipv4,
        ipv6 => $lists_ipv6,
    }

    $list_outbound_ips = [
        pick($lists_ipv4, $facts['ipaddress']),
        pick($lists_ipv6, $facts['ipaddress6']),
    ]

    if $::realm == 'labs' {
        $trusted_networks = ['172.16.0.0/12']
    }
    if $::realm == 'production' {
        $trusted_networks = $network::constants::aggregate_networks.filter |$x| {
            $x !~ /127.0.0.0|::1/
        }
    }

    class { 'spamassassin':
        required_score   => '4.0',
        use_bayes        => '0',
        bayes_auto_learn => '0',
        trusted_networks => $trusted_networks,
    }

    class { 'exim4':
        variant => 'heavy',
        config  => template('profile/exim/exim4.conf.mailman3.erb'),
        filter  => template('profile/exim/system_filter.conf.mailman3.erb'),
        require => [
            Class['spamassassin'],
            Interface::Alias[$host],
        ],
    }

    exim4::dkim { $host:
        domain   => $host,
        selector => 'wikimedia',
        content  => secret("dkim/${host}-wikimedia.key"),
    }

    ferm::service { 'mailman3-smtp':
        proto => 'tcp',
        port  => '25',
    }

    ferm::service { 'mailman3-http':
        proto => 'tcp',
        port  => '80',
    }

    ferm::service { 'mailman3-https':
        proto => 'tcp',
        port  => '443',
    }

    ferm::rule { 'mailman3-spamd-local':
        rule => 'proto tcp dport 783 { saddr (127.0.0.1 ::1) ACCEPT; }'
    }

    monitoring::service { 'smtp':
        description   => 'Exim SMTP',
        check_command => 'check_smtp_tls_le',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Exim',
    }

    monitoring::service { 'https':
        description   => 'HTTPS',
        check_command => "check_ssl_http_letsencrypt!${host}",
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Mailman#Monitoring',
    }

    # mailman3 service
    nrpe::monitor_service { 'procs_mailman3':
        description  => 'mailman3',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -u list --ereg-argument-array=\'/mailman3/bin/master\'',
        notes_url    => 'https://wikitech.wikimedia.org/wiki/Mailman#Monitoring',
    }

    # uwsgi powering mailman3
    nrpe::monitor_service { 'procs_mailman3_web':
        description  => 'mailman3-web',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 2:2 -u www-data --ereg-argument-array=\'/usr/bin/uwsgi\'',
        notes_url    => 'https://wikitech.wikimedia.org/wiki/Mailman#Monitoring',
    }

    file { '/usr/local/lib/nagios/plugins/check_mailman_queue':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => 'puppet:///modules/icinga/check_mailman_queue.py',
    }

    sudo::user { 'nagios_mailman3_queue':
        user       => 'nagios',
        privileges => ['ALL = (list) NOPASSWD: /usr/local/lib/nagios/plugins/check_mailman_queue'],
    }

    nrpe::monitor_service { 'mailman3_queue':
        description  => 'mailman3_queue_size',
        nrpe_command => '/usr/bin/sudo -u list /usr/local/lib/nagios/plugins/check_mailman_queue --mailman3 25 25 25',
        notes_url    => 'https://wikitech.wikimedia.org/wiki/Mailman#Monitoring',
    }

    nrpe::monitor_service { 'mailman3_runners':
        description  => 'mailman3_runners',
        # As of Mailman Core 3.3.3, there are 14 runners
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 14:14 -u list --ereg-argument-array=\'/usr/lib/mailman3/bin/runner\'',
        notes_url    => 'https://wikitech.wikimedia.org/wiki/Mailman#Monitoring',
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


    # rsync from mailman2 to allow importing archives
    if $mailman2_host {
        class { '::mailman3::import_test':
            mailman2_host => $mailman2_host,
            mailman3_host => $::fqdn,
        }
    }
}
