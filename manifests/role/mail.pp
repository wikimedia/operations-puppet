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
