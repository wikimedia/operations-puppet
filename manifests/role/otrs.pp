# vim: set ts=4 et sw=4:
# role/otrs.pp

class role::otrs::webserver {

    $apache_ssl = true,

    system_role { 'role::otrs::webserver': description => 'OTRS Web Application Server' }

    include standard-noexim,
        webserver::apache2

    package {
        ['libapache-dbi-perl', 'libapache2-mod-perl2', 'libdbd-mysql-perl', 'libgd-graph-perl',
        'libgd-text-perl', 'libio-socket-ssl-perl', 'libjson-xs-perl', 'libnet-dns-perl',
        'libnet-ldap-perl', 'libpdf-api2-perl', 'libsoap-lite-perl', 'libtext-csv-xs-perl',
        'libtimedate-perl', 'perl-doc']:
        ensure => 'present',
    }

    install_certificate{ "star.wikimedia.org": }

    file {
        '/etc/apache2/sites-available/ticket.wikimedia.org':
            ensure => present,
            owner => root,
            group => root,
            mode => '0444',
            source => 'puppet:///files/apache/sites/ticket.wikimedia.org';
        #'/etc/apache2/ports.conf':
        #    ensure => present,
        #    mode   => '0444',
        #    owner  => root,
        #    group  => root,
        #    source => 'puppet:///files/apache/ports.conf.ssl';
    }

    apache_site { 'ticket': name => 'ticket.wikimedia.org' }
    apache_module { 'perl': name => 'perl' },
    apache_module { 'rewrite': name => 'rewrite' },

}
