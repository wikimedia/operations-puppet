class role::mail::sender {
    class { 'exim4':
        queuerunner => 'queueonly',
        config      => template('mail/exim4.minimal.erb'),
    }
}

class role::mail::mx {
    include privateexim::aliases::private
    include exim4::ganglia

    class { 'exim::roled':
        local_domains          => [
                '+system_domains',
                '+wikimedia_domains',
                '+legacy_mailman_domains',
                '@mx_primary/ignore=127.0.0.1',
            ],
        enable_mail_relay      => 'primary',
        enable_mail_submission => false,
        enable_external_mail   => true,
        mediawiki_relay        => true,
    }

    monitor_service { 'smtp':
        description   => 'Exim SMTP',
        check_command => 'check_smtp',
    }
}

class role::mail::oldmx {
    include backup::client
    include privateexim::aliases::private
    include exim4::ganglia

    # mails the wikimedia.org mail alias file to OIT once per week
    class { 'misc::maintenance::mail_exim_aliases':
        enabled => true,
    }

    # FIXME: the rest is unpuppetized so far

    monitor_service { 'smtp':
        description   => 'Exim SMTP',
        check_command => 'check_smtp',
    }
}

class role::mail::lists {
    # FIXME: needs to be split to lists/secondarymx

    system::role { 'role::mail::lists':
        description => 'Mailing list server',
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
}

class role::mail::imap {
    # confusingly enough, the former is amanda, the latter is bacula
    include backup::client
    include backup::host
    backup::set { 'var-vmail': }

    # FIXME: the rest is unpuppetized so far
}
