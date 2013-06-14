# Class: exim
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
#   - $enable_imap_delivery:
#       Whether IMAP local delivery functional is enabled (true/false)
#   - $enable_mail_submission:
#       Enable/disable mail submission by users/client MUAs
#   - $mediawiki_relay:
#       Whether this MTA relays mail for MediaWiki (true/false)
#   - $enable_spamasssin:
#       Enable/disable SpamAssassin spam checking
#   - $outbound_ips:
#       IP addresses to use for sending outbound e-mail
#   - $hold_domains:
#       List of domains to hold on the queue without processing
class exim(
    $local_domains = [ "+system_domains" ],
    $enable_mail_relay="false",
    $enable_mailman="false",
    $enable_imap_delivery="false",
    $enable_mail_submission="false",
    $enable_external_mail="false",
    $smart_route_list=[],
    $mediawiki_relay="false",
    $rt_relay="false",
    $enable_spamassassin="false",
    $outbound_ips=[ $ipaddress ],
    $hold_domains=[] ) {

    class { "config": install_type => "heavy", queuerunner => "combined" }
    Class["config"] -> Class[exim]

    include service

    include smtp
    include network::constants
    include exim::listserve::private

    $primary_mx = [ "208.80.152.186", "2620::860:2:219:b9ff:fedd:c027" ]
    file {
        "/etc/exim4/exim4.conf":
            require => Package[exim4-config],
            notify => Service[exim4],
            owner => root,
            group => Debian-exim,
            mode => 0440,
            content => template("exim/exim4.conf.SMTP_IMAP_MM.erb");
        "/etc/exim4/system_filter":
            owner => root,
            group => Debian-exim,
            mode => 0444,
            content => template("exim/system_filter.conf.erb");
        "/etc/exim4/defer_domains":
            owner => root,
            group => Debian-exim,
            mode => 0444,
            ensure => present;
    }

    class mail_relay {
        Class["config"] -> Class[exim::mail_relay]

        file {
            "/etc/exim4/relay_domains":
                owner => root,
                group => root,
                mode => 0444,
                source => "puppet:///modules/exim/exim4.secondary_relay_domains.conf";
        }
    }

    class mailman {
        Class["config"] -> Class[exim::mailman]

        file {
            "/etc/exim4/aliases/lists.wikimedia.org":
                owner => root,
                group => root,
                mode => 0444,
                source => "puppet:///modules/exim/exim4.listserver_aliases.conf";
        }
    }

    if ( $enable_mailman == "true" ) {
        include exim::mailman
    }
    if ( $enable_mail_relay == "primary" ) or ( $enable_mail_relay == "secondary" ) {
        include exim::mail_relay
    }
    if ( $enable_spamassassin == "true" ) {
        include spamassassin
    }
}


class config($install_type="light", $queuerunner="queueonly") {
    package { [ "exim4-config", "exim4-daemon-${install_type}" ]: ensure => latest }

    if $install_type == "heavy" {
        exec { "mkdir /var/spool/exim4/scan":
            require => Package[exim4-daemon-heavy],
            path => "/bin:/usr/bin",
            creates => "/var/spool/exim4/scan"
        }

        mount { [ "/var/spool/exim4/scan", "/var/spool/exim4/db" ]:
            device => "none",
            fstype => "tmpfs",
            options => "defaults",
            ensure => mounted
        }

        file { [ "/var/spool/exim4/scan", "/var/spool/exim4/db" ]:
            ensure => directory,
            owner => Debian-exim,
            group => Debian-exim
        }

        # add nagios to the Debian-exim group to allow check_disk tmpfs mounts (puppet still can't manage existing users?! so just Exec)
        exec { "nagios_to_exim_group":
            command => "usermod -a -G Debian-exim nagios",
            path => "/usr/sbin";
        }

        Exec["mkdir /var/spool/exim4/scan"] -> Mount["/var/spool/exim4/scan"] -> File["/var/spool/exim4/scan"]
        Package[exim4-daemon-heavy] -> Mount["/var/spool/exim4/db"] -> File["/var/spool/exim4/db"]
    }

    file {
        "/etc/default/exim4":
            require => Package[exim4-config],
            owner => root,
            group => root,
            mode => 0444,
            content => template("exim/exim4.default.erb");
        "/etc/exim4/aliases/":
            require => Package[exim4-config],
            mode => 0755,
            owner => root,
            group => root,
            ensure => directory;
    }
}

class service {
    Class["config"] -> Class[service]

    # The init script's status command exit value only reflects the SMTP service
    service { exim4:
        ensure => running,
        hasstatus => $exim::config::queuerunner ? {
            "queueonly" => false,
            default => true
        }
    }

    if $config::queuerunner != "queueonly" {
        # Nagios monitoring
        monitor_service { "smtp": description => "Exim SMTP", check_command => "check_smtp" }
    }
}

class simple-mail-sender {
    class { "config": queuerunner => "queueonly" }
    Class["config"] -> Class[exim::simple-mail-sender]

    file {
        "/etc/exim4/exim4.conf":
            require => Package[exim4-config],
            owner => root,
            group => root,
            mode => 0444,
            content => template("exim/exim4.minimal.erb");
    }

    include service
}

class smtp {
    $otrs_mysql_password = $passwords::exim4::otrs_mysql_password
    $smtp_ldap_password = $passwords::exim4::smtp_ldap_password
}


