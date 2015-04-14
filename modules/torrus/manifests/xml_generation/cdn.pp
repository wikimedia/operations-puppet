# Class: torrus::xml_generation::cdn
#
# This class automatically generates XML files for
# Squid and Varnish servers
#
# Uses role/cache/cache.pp
class torrus::xml_generation::cdn {
    File {
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        notify => Exec['torrus compile --tree=CDN'],
    }
    file { '/etc/torrus/xmlconfig/varnish.xml':
        content => template('torrus/varnish.xml.erb'),
    }

    file { '/etc/torrus/xmlconfig/cdn-aggregates.xml':
        content => template('torrus/cdn-aggregates.xml.erb'),
    }

    exec { 'torrus compile --tree=CDN':
        path        => '/bin:/sbin:/usr/bin:/usr/sbin',
        logoutput   => true,
        refreshonly => true,
    }
}
