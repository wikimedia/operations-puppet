# mail.pp

class exim {
    # Class: exim::roled
    #
    # This class installs a full featured Exim MTA
    #
    # Parameters:
    #   - $enable_mail_relay:
    #       Values: primary, secondary
    #       Whether Exim will act as a primary or secondary mail relay for
    #       other mail servers
    #   - $enable_mailman:
    #       Whether Mailman delivery functionality is enabled (true/false)
    #   - $outbound_ips:
    #       IP addresses to use for sending outbound e-mail
    #   - $list_outbound_ips:
    #       IP addresses to use for sending outbound e-mail from Mailman
    #   - $verp_domains:
    #       List of domains for which VERP responses should be POST-ed to the MediaWiki 'bouncehandler' API for processing
    #   - $verp_post_connect_server:
    #       External hostname to connect while HTTP POST-ing a bounced email to the MediaWiki 'bouncehandler' API
    #   - $verp_bounce_post_url:
    #       Internal hostname of the wiki to which verp bounce emails are HTTP POST-ed and processed
    class roled(
        $enable_mail_relay=false,
        $enable_mailman=false,
        $enable_otrs_server=false,
        $list_outbound_ips=[],
        $outbound_ips=[ ],
        $verp_domains=[],
        $verp_post_connect_server='',
        $verp_bounce_post_url='',
) {
        include exim4::ganglia

        include passwords::exim
        $otrs_mysql_password = $passwords::exim::otrs_mysql_password
        $smtp_ldap_password  = $passwords::exim::smtp_ldap_password

        if $enable_otrs_server {
            $config_template = template('exim/exim4.conf.otrs.erb')
            $filter_template = template('exim/system_filter.conf.otrs.erb')
        } elsif $enable_mailman {
            $config_template = template('exim/exim4.conf.mailman.erb')
            $filter_template = template('exim/system_filter.conf.mailman.erb')
        } elsif $enable_mail_relay {
            $config_template = template('exim/exim4.conf.mx.erb')
            $filter_template = template('exim/system_filter.conf.erb')
        } else {
            fail('Unrecognized exim role type')
        }

        class { 'exim4':
            variant => 'heavy',
            config  => $config_template,
            filter  => $filter_template,
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

        if $enable_mail_relay {
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
        }

        if $enable_mailman {
            include privateexim::listserve

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
    }
}
