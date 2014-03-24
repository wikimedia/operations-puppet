# vim: set ts=4 et sw=4:
# role/otrs.pp

class role::otrs {
    system::role { 'role::otrs::webserver': description => 'OTRS Web Application Server' }

    $nagios_group = "${cluster}_${::site}"

    include standard-noexim
    include webserver::apache
    include nrpe
    include network::constants

    generic::systemuser { 'otrs':
        name => 'otrs',
        home => '/var/lib/otrs',
        groups => 'www-data',
        shell => "/bin/bash",
    }

    package {
        ['libapache-dbi-perl', 'libapache2-mod-perl2', 'libdbd-mysql-perl', 'libgd-graph-perl',
        'libgd-text-perl', 'libio-socket-ssl-perl', 'libjson-xs-perl', 'libnet-dns-perl',
        'libnet-ldap-perl', 'libpdf-api2-perl', 'libsoap-lite-perl', 'libtext-csv-xs-perl',
        'libtimedate-perl', 'perl-doc', 'mysql-client']:
        ensure => 'present',
    }

    file {
        '/etc/apache2/sites-available/ticket.wikimedia.org':
            ensure => present,
            owner => root,
            group => root,
            mode => '0444',
            source => 'puppet:///files/apache/sites/ticket.wikimedia.org';
        '/etc/cron.d/otrs':
            ensure => present,
            owner => root,
            group => root,
            mode => '0444',
            source => 'puppet:///files/otrs/crontab.otrs';
        '/var/spool/spam':
            ensure => directory,
            owner => otrs,
            group => www-data,
            mode => '0775';
        '/opt/otrs/bin/otrs.TicketExport2Mbox.pl':
            ensure => present,
            owner => otrs,
            group => www-data,
            mode => '0755',
            source => 'puppet:///files/otrs/otrs.TicketExport2Mbox.pl';
        '/opt/otrs/bin/cgi-bin/idle_agent_report':
            ensure => present,
            owner => otrs,
            group => www-data,
            mode => '0755',
            source => 'puppet:///files/otrs/idle_agent_report';
        '/usr/local/bin/train_spamassassin':
            ensure => present,
            owner => root,
            group => root,
            mode => '0555',
            source => 'puppet:///files/otrs/train_spamassassin';
        '/opt/otrs/Kernel/Output/HTML/OTRS':
            ensure => link,
            target => '/opt/otrs/Kernel/Output/HTML/Standard';
    }

    install_certificate{ "ticket.wikimedia.org": ca => "RapidSSL_CA.pem" }
    apache_module { 'perl': name => 'perl' }
    apache_module { 'rewrite': name => 'rewrite' }
    apache_module { 'ssl': name => 'ssl' }
    apache_site { 'ticket': name => 'ticket.wikimedia.org' }

    class { 'spamassassin':
        required_score => '3.5',
        use_bayes => '1',
        bayes_auto_learn => '0',
        short_report_template => 'true',
        spamd_user => 'otrs',
        spamd_group => 'otrs',
        trusted_networks => $network::constants::all_networks,
        custom_scores => {
            'RP_MATCHES_RCVD'   => '-0.500',
            'SPF_SOFTFAIL'      => '2.000',
            'SUSPICIOUS_RECIPS' => '2.000',
            'DEAR_SOMETHING'    => '1.500',
        },
    }

    class { 'exim::roled':
        enable_clamav => 'true',
        enable_otrs_server => 'true',
        enable_spamassassin => 'true',
        enable_external_mail => 'true',
        smart_route_list => [ 'mchenry.wikimedia.org', 'lists.wikimedia.org' ],
    }

    cron { 'otrs_train_spamassassin':
        user => root,
        minute => 5,
        command => '/usr/local/bin/train_spamassassin',
        ensure => present;
    }

    monitor_service { "https":
        description => "HTTPS",
        check_command => "check_ssl_cert!*.wikimedia.org",
    }

}
