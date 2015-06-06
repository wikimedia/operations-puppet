class role::mail::sender {
    class { 'exim4':
        queuerunner => 'queueonly',
        config      => template("mail/exim4.minimal.${::realm}.erb"),
    }
}

class role::mail::mx(
    $verp_domains = [
        'wikimedia.org'
    ],
    $verp_post_connect_server = 'test2.wikipedia.org',
    $verp_bounce_post_url = "api.svc.${::mw_primary}.wmnet/w/api.php",
) {
    include network::constants
    include privateexim::aliases::private

    system::role { 'role::mail::mx':
        description => 'Mail router',
    }

    mailalias { 'root':
        recipient => 'root@wikimedia.org',
    }

    class { 'spamassassin':
        required_score   => '4.0',
        use_bayes        => '1',
        bayes_auto_learn => '1',
        trusted_networks => $network::constants::all_networks,
    }

    include passwords::exim
    $otrs_mysql_password = $passwords::exim::otrs_mysql_password
    $smtp_ldap_password  = $passwords::exim::smtp_ldap_password

    class { 'exim4':
        variant => 'heavy',
        config  => template('exim/exim4.conf.mx.erb'),
        filter  => template('exim/system_filter.conf.erb'),
        require => Class['spamassassin'],
    }
    include exim4::ganglia

    file { '/etc/exim4/defer_domains':
        ensure  => present,
        owner   => 'root',
        group   => 'Debian-exim',
        mode    => '0444',
        require => Class['exim4'],
    }

    file { '/etc/exim4/wikimedia_domains':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///files/exim/wikimedia_domains',
        require => Class['exim4'],
    }

    file { '/etc/exim4/legacy_mailing_lists':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///files/exim/legacy_mailing_lists',
        require => Class['exim4'],
    }
    exim4::dkim { 'wikimedia.org':
        domain   => 'wikimedia.org',
        selector => 'wikimedia',
        source   => 'puppet:///private/dkim/wikimedia.org-wikimedia.key',
    }
    exim4::dkim { 'wiki-mail':
        domain   => 'wikimedia.org',
        selector => 'wiki-mail',
        source   => 'puppet:///private/dkim/wikimedia.org-wiki-mail.key',
    }

    monitoring::service { 'smtp':
        description   => 'Exim SMTP',
        check_command => 'check_smtp',
    }

    # mails the wikimedia.org mail alias file to OIT once per week
    $alias_file = '/etc/exim4/aliases/wikimedia.org'
    $recipient  = 'officeit@wikimedia.org'
    $subject    = "wikimedia.org mail aliases from ${::hostname}"
    cron { 'mail_exim_aliases':
        user    => 'Debian-exim',
        minute  => 0,
        hour    => 0,
        weekday => 0,
        command => "/usr/bin/mail -s '${subject}' ${recipient} < ${alias_file} >/dev/null 2>&1",
    }
}

class role::mail::lists {
    include network::constants

    system::role { 'role::mail::lists':
        description => 'Mailing list server',
    }

    mailalias { 'root':
        recipient => 'root@wikimedia.org',
    }

    interface::ip { 'lists.wikimedia.org_v4':
        interface => 'eth0',
        address   => '208.80.154.4',
        prefixlen => '32',
    }

    interface::ip { 'lists.wikimedia.org_v6':
        interface => 'eth0',
        address   => '2620:0:861:1::2',
        prefixlen => '128',
    }

    $outbound_ips = [
            '208.80.154.61',
            '2620:0:861:1:208:80:154:61'
    ]
    $list_outbound_ips = [
            '208.80.154.4',
            '2620:0:861:1::2'
    ]

    install_certificate{ 'lists.wikimedia.org': }

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
        config  => template('exim/exim4.conf.mailman.erb'),
        filter  => template('exim/system_filter.conf.mailman.erb'),
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
        source  => 'puppet:///files/exim/listserver_aliases',
        require => Class['exim4'],
    }

    exim4::dkim { 'lists.wikimedia.org':
        domain   => 'lists.wikimedia.org',
        selector => 'wikimedia',
        source   => 'puppet:///private/dkim/lists.wikimedia.org-wikimedia.key',
    }

    include role::backup::host
    backup::set { 'var-lib-mailman': }

    monitoring::service { 'smtp':
        description   => 'Exim SMTP',
        check_command => 'check_smtp',
    }

    monitoring::service { 'https':
        description   => 'HTTPS',
        check_command => 'check_ssl_http!lists.wikimedia.org',
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
        check_command => 'check_https_url_for_string!lists.wikimedia.org!/mailman/listinfo/wikimedia-l!\'Discussion list for the Wikimedia community\'',
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
        source => 'puppet:///files/icinga/check_mailman_queue',
    }

    nrpe::monitor_service { 'mailman_queue':
        description   => 'mailman_queue_size',
        nrpe_command  => '/usr/local/lib/nagios/plugins/check_mailman_queue 42',
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
        source => 'puppet:///files/icinga/check_iostat',
    }

    # values chosen based on i/o averages for sodium
    nrpe::monitor_service { 'mailman_iostat':
        description   => 'mailman I/O stats',
        nrpe_command  => '/usr/local/lib/nagios/plugins/check_iostat -i -w 250,350,300,14000,7500 -c 500,400,600,28000,11000',
        timeout       => '30',
    }

}
