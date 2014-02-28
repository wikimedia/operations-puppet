# sets up Apache site for a WMF RT install
class requesttracker::apache($apache_site) {

    if ! defined(Class['webserver::php5']) {
        class { 'webserver::php5':
            ssl => true,
        }
    }

    install_certificate{ $apache_site: }

    apache::site { 'rt.wikimedia.org':
        content => template('requesttracker/rt4.apache.erb'),
    }

    # use this to have a NameVirtualHost *:443
    # avoid [warn] _default_ VirtualHost overlap
    apache::conf { 'rt-apache-ports':
        source => 'puppet:///modules/requesttracker/ports.conf.ssl',
    }

    include ::apache::mod::perl

}

