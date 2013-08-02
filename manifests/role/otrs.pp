# vim: set ts=4 et sw=4:
# role/otrs.pp

class role::otrs::webserver {

    system_role { 'role::otrs::webserver': description => 'OTRS Web Application Server' }

    package { ['libapache2-mod-perl2', 'libdbd-mysql-perl', 'libtimedate-perl', 'libnet-dns-perl', 'libnet-ldap-perl',
        'libio-socket-ssl-perl', 'libpdf-api2-perl', 'libdbd-mysql-perl', 'libsoap-lite-perl', 'libgd-text-perl',
        'libtext-csv-xs-perl', 'libjson-xs-perl', 'libgd-graph-perl', 'libapache-dbi-perl', 'perl-doc']:
        ensure => 'present',
    }

    install_certificate{ "star.wikimedia.org": }

    # enable modperl
    #apache_module { 'perl': name => 'perl', }

    file {
        '/etc/apache2/sites-available/ticket.wikimedia.org':
            ensure => present,
            owner => root,
            group => root,
            mode => '0444',
            source => 'puppet:///files/apache/sites/ticket.wikimedia.org',
        #'/etc/apache2/ports.conf':
        #    ensure => present,
        #    mode   => '0444',
        #    owner  => root,
        #    group  => root,
        #    source => 'puppet:///files/apache/ports.conf.ssl';
    }

    apache_site { 'ticket': name => 'ticket.wikimedia.org' }

}
