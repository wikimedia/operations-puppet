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

    # MediaWiki VERP bounce processor config - labs vs. production
    case $::realm {
        'labs': {
            $verp_domains   = [
                    'deployment.wikimedia.beta.wmflabs.org'
                ]
            $verp_post_connect_server = 'deployment.wikimedia.beta.wmflabs.org'
            $verp_bounce_post_url     = 'http://deployment.wikimedia.beta.wmflabs.org/w/api.php'
        }
        'production': {
            # currently not used as bouncehandler extension is not yet installed in production
            # the api urls should change once the extension gets installed
            $verp_domains   = [ ]
            $verp_post_connect_server = 'login.wikimedia.org'
            $verp_bounce_post_url     = "appservers.svc.${::mw_primary}.wmnet/w/api.php"
        }
        default: {
            fail('unknown realm, should be labs or production')
        }
    }

    class { 'exim::roled':
        local_domains          => [
                '+system_domains',
                '+wikimedia_domains',
                '+legacy_mailman_domains',
            ],
        enable_mail_relay        => 'primary',
        enable_mail_submission   => false,
        enable_external_mail     => true,
        mediawiki_relay          => true,
        enable_spamassassin      => true,
        verp_domains             => $verp_domains,
        verp_post_connect_server => $verp_post_connect_server,
        verp_bounce_post_url     => $verp_bounce_post_url,
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
    include backup::host
    backup::set { 'var-lib-mailman': }

    monitor_service { 'smtp':
        description   => 'Exim SMTP',
        check_command => 'check_smtp',
    }

    nrpe::monitor_service { 'procs_mailmanctl':
        description  => 'mailman_ctl',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -u list --ereg-argument-array=\'/mailman/bin/mailmanctl\''
    }

    nrpe::monitor_service { 'procs_mailman_qrunner':
        description  => 'mailman_qrunner',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 8:8 -u list --ereg-argument-array=\'/mailman/bin/qrunner\''
    }

    monitor_service { 'mailman_listinfo':
        description   => 'mailman list info',
        check_command => 'check_https_url_for_string!lists.wikimedia.org!/mailman/listinfo/wikimedia-l!\'Discussion list for the Wikimedia community\'',
    }

    monitor_service { 'mailman_archives':
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

}

class role::mail::imap {
    # confusingly enough, the former is amanda, the latter is bacula
    include backup::host
    backup::set { 'var-vmail': }

    # FIXME: the rest is unpuppetized so far
}
