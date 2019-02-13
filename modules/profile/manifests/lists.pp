class profile::lists {
    include ::network::constants
    include ::mailman
    include ::privateexim::listserve

    mailalias { 'root': recipient => 'root@wikimedia.org' }

    interface::alias { 'lists.wikimedia.org':
        ipv4 => hiera('mailman::lists::ipv4', undef),
        ipv6 => hiera('mailman::lists::ipv6', undef),
    }

    class { '::sslcert::dhparam': }
    certcentral::cert{ 'lists':
        puppet_svc => 'apache2',
        key_group  => 'Debian-exim',
    }
    acme_chief::cert{ 'lists':
        puppet_svc => 'apache2',
        key_group  => 'Debian-exim',
    }

    $trusted_networks = $network::constants::aggregate_networks.filter |$x| {
        $x !~ /127.0.0.0|::1/
    }

    class { 'spamassassin':
        required_score   => '4.0',
        use_bayes        => '0',
        bayes_auto_learn => '0',
        trusted_networks => $trusted_networks,
    }

    $list_outbound_ips = [
        hiera('mailman::lists::ipv4'),
        hiera('mailman::lists::ipv6'),
    ]

    class { '::exim4':
        variant => 'heavy',
        config  => template('profile/exim/exim4.conf.mailman.erb'),
        filter  => template('profile/exim/system_filter.conf.mailman.erb'),
        require => [
            Class['spamassassin'],
            Interface::Alias['lists.wikimedia.org'],
        ],
    }

    file { '/etc/exim4/aliases/lists.wikimedia.org':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///modules/profile/exim/listserver_aliases',
        require => Class['exim4'],
    }

    exim4::dkim { 'lists.wikimedia.org':
        domain   => 'lists.wikimedia.org',
        selector => 'wikimedia',
        content  => secret('dkim/lists.wikimedia.org-wikimedia.key'),
    }

    backup::set { 'var-lib-mailman': }

    monitoring::service { 'smtp':
        description   => 'Exim SMTP',
        check_command => 'check_smtp_tls_le',
    }

    monitoring::service { 'https':
        description   => 'HTTPS',
        check_command => 'check_ssl_http_letsencrypt!lists.wikimedia.org',
    }

    nrpe::monitor_service { 'procs_mailmanctl':
        description  => 'mailman_ctl',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -u list --ereg-argument-array=\'/mailman/bin/mailmanctl\''
    }

    nrpe::monitor_service { 'procs_mailman_qrunner':
        description  => 'mailman_qrunner',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 8:8 -u list --ereg-argument-array=\'/mailman/bin/qrunner\''
    }

    monitoring::service { 'mailman_listinfo':
        description   => 'mailman list info',
        check_command => 'check_https_url_for_string!lists.wikimedia.org!/mailman/listinfo/wikimedia-l!\'Wikimedia Mailing List\'',
    }

    monitoring::service { 'mailman_archives':
        description   => 'mailman archives',
        check_command => 'check_https_url_for_string!lists.wikimedia.org!/pipermail/wikimedia-l/!\'The Wikimedia-l Archives\'',
    }

    file { '/usr/local/lib/nagios/plugins/check_mailman_queue':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => 'puppet:///modules/icinga/check_mailman_queue.sh',
    }

    sudo::user { 'nagios_mailman_queue':
        user       => 'nagios',
        privileges => ['ALL = (list) NOPASSWD: /usr/local/lib/nagios/plugins/check_mailman_queue'],
    }

    nrpe::monitor_service { 'mailman_queue':
        description  => 'mailman_queue_size',
        nrpe_command => '/usr/bin/sudo -u list /usr/local/lib/nagios/plugins/check_mailman_queue 25 25 25',
    }

    ferm::service { 'mailman-smtp':
        proto => 'tcp',
        port  => '25',
    }

    ferm::service { 'mailman-http':
        proto => 'tcp',
        port  => '80',
    }

    ferm::service { 'mailman-https':
        proto => 'tcp',
        port  => '443',
    }

    ferm::rule { 'mailman-spamd-local':
        rule => 'proto tcp dport 783 { saddr (127.0.0.1 ::1) ACCEPT; }'
    }
}
