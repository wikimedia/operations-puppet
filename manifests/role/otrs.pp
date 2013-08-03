# vim: set ts=4 et sw=4:
# role/otrs.pp

class role::otrs {
    include role::otrs::webserver,
        role::otrs::mailserver

    systemuser { 'otrs':
        name => 'otrs',
        home => '/opt/otrs-home',
        groups => 'www-data'
    }
}


class role::otrs::webserver {
    system_role { 'role::otrs::webserver': description => 'OTRS Web Application Server' }
    include standard-noexim,
        webserver::apache
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
    }
    install_certificate{ "star.wikimedia.org": }
    apache_module { 'perl': name => 'perl' }
    apache_module { 'rewrite': name => 'rewrite' }
    apache_module { 'ssl': name => 'ssl' }
    apache_site { 'ticket': name => 'ticket.wikimedia.org' }
}


class role::otrs::mailserver {
    include passwords::exim4,
        network::constants

    class { 'spamassassin':
        required_score => '5.0',
        use_bayes => 1,
        bayes_auto_learn => 1
    }

    package { [ 'exim4-daemon-heavy', 'exim4-config' ]:
        ensure => latest;
    }
    File {
        owner => root,
        group => root,
        mode => '0444',
    }
    file {
        '/etc/exim4/exim4.conf':
            ensure => present,
            content => template('exim/exim4.otrs.erb');
        '/etc/exim4/system_filter':
            ensure => present,
            source => 'puppet:///files/exim/system_filter.otrs';
    }
}
