# sets up Apache site for a WMF RT install
class requesttracker::apache($apache_site) {

    if ! defined(Class['webserver::php5']) {
        class { 'webserver::php5':
            ssl => true,
        }
    }

    install_certificate{ $apache_site: }


    file { "/etc/apache2/sites-available/${apache_site}":
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template('requesttracker/rt4.apache.erb'),
    }

    # use this to have a NameVirtualHost *:443
    # avoid [warn] _default_ VirtualHost overlap

    file { '/etc/apache2/ports.conf':
        ensure => 'present',
        mode   => '0444',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/requesttracker/ports.conf.ssl',
    }

    apache_module { 'perl':
        name => 'perl',
    }

    apache_site { $apache_site:
        name => $apache_site,
    }

}

