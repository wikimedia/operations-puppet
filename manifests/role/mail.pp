class role::mail::oldmx {
    include privateexim::aliases::private
    include exim::stats

    # mails the wikimedia.org mail alias file to OIT once per week
    class { 'misc::maintenance::mail_exim_aliases':
        enabled => true,
    }

    # FIXME: the rest is unpuppetized so far
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
    }

    include mailman
    include backup::client

    include clamav
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
        enable_mailman         => 'true',
        enable_mail_submission => 'false',
        enable_spamassassin    => 'true',
        require                => [
            Class['spamassassin'],
            Interface::Ip['lists.wikimedia.org_v4'],
            Interface::Ip['lists.wikimedia.org_v6'],
        ],
    }
}
