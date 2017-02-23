class role::lists::server {
    include network::constants
    include ::base::firewall
    include ::standard

    system::role { 'role::lists::server':
        description => 'Mailing list server',
    }

    mailalias { 'root':
        recipient => 'root@wikimedia.org',
    }

    $lists_ip = hiera('mailman::lists_ip')

    interface::ip { 'lists.wikimedia.org_v4':
        interface => 'eth0',
        address   => $lists_ip[0],
        prefixlen => '32',
    }

    interface::ip { 'lists.wikimedia.org_v6':
        interface => 'eth0',
        address   => $lists_ip[1],
        prefixlen => '128',
    }

    $outbound_ips = hiera_array('mailman::server_ip')
    $list_outbound_ips = hiera_array('mailman::lists_ip')

    letsencrypt::cert::integrated { 'lists':
        subjects   => 'lists.wikimedia.org',
        puppet_svc => 'apache2',
        system_svc => 'apache2',
        key_group  => 'Debian-exim',
    }

    include mailman

    class { 'spamassassin':
        required_score   => '4.0',
        use_bayes        => '0',
        bayes_auto_learn => '0',
        trusted_networks => $network::constants::all_networks,
    }

    include privateexim::listserve

    class { 'exim4':
        variant => 'heavy',
        config  => template('role/exim/exim4.conf.mailman.erb'),
        filter  => template('role/exim/system_filter.conf.mailman.erb'),
        require => [
            Class['spamassassin'],
            Interface::Ip['lists.wikimedia.org_v4'],
            Interface::Ip['lists.wikimedia.org_v6'],
        ],
    }
    include exim4::ganglia

    file { '/etc/exim4/aliases/lists.wikimedia.org':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///modules/role/exim/listserver_aliases',
        require => Class['exim4'],
    }

    exim4::dkim { 'lists.wikimedia.org':
        domain   => 'lists.wikimedia.org',
        selector => 'wikimedia',
        content  => secret('dkim/lists.wikimedia.org-wikimedia.key'),
    }

    include ::role::backup::host
    backup::set { 'var-lib-mailman': }

    monitoring::service { 'smtp':
        description   => 'Exim SMTP',
        check_command => 'check_smtp_tls',
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

    # on list servers we monitor I/O with iostat
    # the icinga plugin needs bc to compare floating point numbers
    package { 'bc':
        ensure => present,
    }

    file { '/usr/local/lib/nagios/plugins/check_iostat':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => 'puppet:///modules/icinga/check_iostat.sh',
    }

    # lint:ignore:quoted_booleans
    $iostat_device = $::is_virtual ? {
        'true'    => 'vda',
        'false'   => 'sda',
        default   => 'sda',
    }
    # lint:endignore

    nrpe::monitor_service { 'mailman_iostat':
        description  => 'mailman I/O stats',
        nrpe_command => "/usr/local/lib/nagios/plugins/check_iostat \
                        -i -w 250,350,300,14000,7500 -c 500,400,600,28000,11000 -d ${iostat_device}",
        timeout      => '30',
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
