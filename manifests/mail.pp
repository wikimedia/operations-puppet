# mail.pp

class exim {
    class smtp {
        include passwords::exim
        $otrs_mysql_password = $passwords::exim::otrs_mysql_password
        $smtp_ldap_password  = $passwords::exim::smtp_ldap_password
    }

    # Class: exim::roled
    #
    # This class installs a full featured Exim MTA
    #
    # Parameters:
    #   - $local_domains:
    #       List of domains Exim will treat as "local", i.e. be responsible
    #       for
    #   - $enable_mail_relay:
    #       Values: primary, secondary
    #       Whether Exim will act as a primary or secondary mail relay for
    #       other mail servers
    #   - $enable_mailman:
    #       Whether Mailman delivery functionality is enabled (true/false)
    #   - $mediawiki_relay:
    #       Whether this MTA relays mail for MediaWiki (true/false)
    #   - $enable_spamasssin:
    #       Enable/disable SpamAssassin spam checking
    #   - $outbound_ips:
    #       IP addresses to use for sending outbound e-mail
    #   - $list_outbound_ips:
    #       IP addresses to use for sending outbound e-mail from Mailman
    #   - $hold_domains:
    #       List of domains to hold on the queue without processing
    #   - $verp_domains:
    #       List of domains for which VERP responses should be POST-ed to the MediaWiki 'bouncehandler' API for processing
    #   - $verp_post_connect_server:
    #       External hostname to connect while HTTP POST-ing a bounced email to the MediaWiki 'bouncehandler' API
    #   - $verp_bounce_post_url:
    #       Internal hostname of the wiki to which verp bounce emails are HTTP POST-ed and processed
    class roled(
        $enable_clamav=false,
        $enable_external_mail=true,
        $enable_mail_relay=false,
        $enable_mailman=false,
        $enable_otrs_server=false,
        $enable_spamassassin=false,
        $hold_domains=[],
        $list_outbound_ips=[],
        $local_domains = [ '+system_domains' ],
        $mediawiki_relay=false,
        $outbound_ips=[ ],
        $rt_relay=false,
        $phab_relay=false,
        $smart_route_list=[],
        $verp_domains=[],
        $verp_post_connect_server='',
        $verp_bounce_post_url='',
) {

        include exim::smtp
        include privateexim::listserve
        include exim4::ganglia

        class { 'exim4':
            variant => 'heavy',
            config  => template('exim/exim4.conf.SMTP_IMAP_MM.erb'),
            filter  => template('exim/system_filter.conf.erb'),
        }

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

        class mail_relay {
            exim4::dkim { 'wikimedia.org':
                domain   => 'wikimedia.org',
                selector => 'wikimedia',
                source   => 'puppet:///private/dkim/wikimedia.org-wikimedia.key',
            }
        }

        class mailman {
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
        }

        if ( $mediawiki_relay == true ) {
            exim4::dkim { 'wiki-mail':
                domain   => 'wikimedia.org',
                selector => 'wiki-mail',
                source   => 'puppet:///private/dkim/wikimedia.org-wiki-mail.key',
            }
        }

        include exim4::ganglia

        if ( $enable_mailman == true ) {
            include mailman
        }
        if ( $enable_mail_relay == 'primary' ) or ( $enable_mail_relay == 'secondary' ) {
            include mail_relay
        }
    }
}

class mailman {
    class listserve {
        package { 'mailman':
            ensure => present,
        }

        system::role { 'mailman::listserve':
            description => 'Mailman listserver',
        }

        file { '/etc/mailman/mm_cfg.py':
            owner  => 'root',
            group  => 'root',
            mode   => '0444',
            source => 'puppet:///files/mailman/mm_cfg.py',
        }

        # Install as many languages as possible
        include locales::extended

        debconf::set { 'mailman/gate_news':
            value  => 'false',
            notify => Exec['dpkg-reconfigure mailman'],
        }

        debconf::set { 'mailman/site_languages':
            value  => 'ar, ast, ca, cs, da, de, en, es, et, eu, fi, fr, gl, he, hr, hu, ia, it, ja, ko, lt, nl, no, pl, pt, pt_BR, ro, ru, sk, sl, sr, sv, tr, uk, vi, zh_CN, zh_TW',
            notify => Exec['dpkg-reconfigure mailman'],
        }

        debconf::set { 'mailman/default_server_language':
            value  => 'en',
            notify => Exec['dpkg-reconfigure mailman'],
        }

        exec { 'dpkg-reconfigure mailman':
            require     => Class['locales::extended'],
            before      => Service['mailman'],
            command     => '/usr/sbin/dpkg-reconfigure -fnoninteractive mailman',
            refreshonly => true
        }

        service { 'mailman':
            ensure    => running,
            hasstatus => false,
            pattern   => 'mailmanctl',
        }

    }

    class web-ui {
        include ::apache
        apache::mod_conf { [
            'ssl',
            'rewrite',
            'alias',
            'setenvif',
            'auth_digest',
        ]: }

        if ( $::realm == 'production' ) {
            install_certificate{ 'lists.wikimedia.org':
                ca => 'RapidSSL_CA.pem',
            }
        }

        # htdigest file for private list archives
        file { '/etc/apache2/arbcom-l.htdigest':
            source  => 'puppet:///private/mailman/arbcom-l.htdigest',
            owner   => 'root',
            group   => 'www-data',
            mode    => '0440',
            require => Class['apache2'],
        }

        apache::site { 'lists.wikimedia.org':
            content => template('apache/sites/lists.wikimedia.org.erb'),
        }

        # Add files in /var/www (docroot)
        file { '/var/www':
            source  => 'puppet:///files/mailman/docroot/',
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            recurse => 'remote',
        }

        # Add a new default theme to make mailman prettier
        file { '/var/lib/mailman/templates':
            ensure  => link,
            target  => '/etc/mailman',
        }

        # Add default theme to make mailman prettier.
        #  Recurse => remote adds a bunch of files here and there
        #  while leaving the by-hand mailman config files in place.
        file { '/etc/mailman':
            source  => 'puppet:///files/mailman/templates/',
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            recurse => 'remote',
        }

        # monitor SSL cert expiry
        if ( $::realm == 'production' ) {
            monitoring::service { 'https':
                description   => 'HTTPS',
                check_command => 'check_ssl_http!lists.wikimedia.org',
            }
        }
    }

    include listserve
    include web-ui
}
