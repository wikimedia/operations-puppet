# vim: set ts=4 et sw=4:
# role/otrs.pp

class role::otrs {
    system_role { 'role::otrs::webserver': description => 'OTRS Web Application Server' }

    $nagios_group = "${cluster}_${::site}"

    include standard-noexim,
        webserver::apache,
        nrpe

    systemuser { 'otrs':
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
    }

    install_certificate{ "star.wikimedia.org": }
    apache_module { 'perl': name => 'perl' }
    apache_module { 'rewrite': name => 'rewrite' }
    apache_module { 'ssl': name => 'ssl' }
    apache_site { 'ticket': name => 'ticket.wikimedia.org' }

    class { 'spamassassin':
        required_score => '4.0',
        use_bayes => '1',
        bayes_auto_learn => '1',
        short_report_format => 'true',
    }

    class { 'exim::roled':
        enable_otrs_server => 'true',
        enable_spamassassin => 'false',
        enable_external_mail => 'true',
        smart_route_list => [ 'mchenry.wikimedia.org', 'lists.wikimedia.org' ],
    }
}
