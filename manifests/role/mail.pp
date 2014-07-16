class role::mail::sender {
    class { 'exim4':
        queuerunner => 'queueonly',
        config      => template('mail/exim4.minimal.erb'),
    }
}

class role::mail::mx {
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

    class { 'exim::roled':
        local_domains          => [
                '+system_domains',
                '+wikimedia_domains',
                '+legacy_mailman_domains',
            ],
        enable_mail_relay      => 'primary',
        enable_mail_submission => false,
        enable_external_mail   => true,
        mediawiki_relay        => true,
        enable_spamassassin    => true,
    }

    Class['spamassassin'] -> Class['exim::roled']

    monitor_service { 'smtp':
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

class role::mail::oldmx {
    include backup::client
    include privateexim::aliases::private
    include exim4::ganglia

    monitor_service { 'smtp':
        description   => 'Exim SMTP',
        check_command => 'check_smtp',
    }

    # FIXME: the rest is unpuppetized so far
}

class role::mail::lists {
    include network::constants

    # FIXME: needs to be split to lists/secondarymx

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

    include mailman

    class { 'spamassassin':
        required_score   => '4.0',
        use_bayes        => '0',
        bayes_auto_learn => '0',
        trusted_networks => $network::constants::all_networks,
    }

    class { 'exim::roled':
        outbound_ips           => [
                '208.80.154.61',
                '2620:0:861:1:208:80:154:61'
            ],
        list_outbound_ips      => [
                '208.80.154.4',
                '2620:0:861:1::2'
            ],
        local_domains          => [
                '+system_domains',
                '+mailman_domains'
            ],
        enable_mail_relay      => 'secondary',
        enable_mailman         => true,
        enable_mail_submission => false,
        enable_spamassassin    => true,
        require                => [
            Interface::Ip['lists.wikimedia.org_v4'],
            Interface::Ip['lists.wikimedia.org_v6'],
        ],
    }

    Class['spamassassin'] -> Class['exim::roled']

    # confusingly enough, the former is amanda, the latter is bacula
    include backup::client
    include backup::host
    backup::set { 'var-lib-mailman': }

    monitor_service { 'smtp':
        description   => 'Exim SMTP',
        check_command => 'check_smtp',
    }

    nrpe::monitor_service { 'procs_mailman':
        description  => 'mailman',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 9:9 -a mailman',
    }

    monitor_service { 'mailman_archives_web':
        description   => 'lists.wikimedia.org',
        check_command => 'check_http_url!lists.wikimedia.org!pipermail/wikimedia-l/',
    }

    monitor_service { 'mailman__web_cgi':
        description   => 'lists.wikimedia.org',
        check_command => 'check_http_url!lists.wikimedia.org!/mailman/listinfo/wikimedia-l',
    }

}

class role::mail::imap {
    # confusingly enough, the former is amanda, the latter is bacula
    include backup::client
    include backup::host
    backup::set { 'var-vmail': }

    # FIXME: the rest is unpuppetized so far
}
