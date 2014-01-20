class torrus::xml-generation {
# Class: misc::torrus::xml-generation
#
# This class automatically generates XML files for
# Squid and Varnish servers
#
# Uses role/cache/cache.pp
    require role::cache::configuration
    include xmlconfig,
        discovery

    file { '/etc/torrus/xmlconfig/varnish.xml':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Exec['torrus compile --tree=CDN'],
        content => template('torrus/varnish.xml.erb'),
    }

    file { '/etc/torrus/xmlconfig/squid.xml':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Exec['torrus compile --tree=CDN'],
        content => template('torrus/squid.xml.erb'),
    }

    file { '/etc/torrus/xmlconfig/cdn-aggregates.xml':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Exec['torrus compile --tree=CDN'],
        content => template('torrus/cdn-aggregates.xml.erb'),
    }

    exec { 'torrus compile --tree=CDN':
        path        => '/bin:/sbin:/usr/bin:/usr/sbin',
        logoutput   => true,
        refreshonly => true;
    }
}
