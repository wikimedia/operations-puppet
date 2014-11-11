class puppet::self::geoip {
    # Fetch the GeoIP databases into puppet's volatile dir, so that other hosts
    # can then just sync that directory into their own /usr/share/GeoIP via a
    # normal puppet File resource (see the geoip module for more)

    $geoip_destdir = '/var/lib/puppet/volatile/GeoIP'

    # geoip::data classes depend on this
    file { $geoip_destdir:
        ensure => directory,
    }

    # fetch the GeoLite databases
    class { 'geoip::data::lite':
        data_directory => $geoip_destdir,
    }

    # compatibility symlinks, so that users can use the stable paths
    # GeoIP.dat/GeoIPCity.dat between labs and production
    file { "$geoip_destdir/GeoIP.dat":
        ensure => link,
        target => 'GeoLite.dat',
    }
    file { "$geoip_destdir/GeoIPCity.dat":
        ensure => link,
        target => 'GeoLiteCity.dat',
    }
    file { "$geoip_destdir/GeoIP2-Country.mmdb":
        ensure => link,
        target => 'GeoLite2-Country.mmdb',
    }
    file { "$geoip_destdir/GeoIP2-City.mmdb":
        ensure => link,
        target => 'GeoLite2-City.mmdb',
    }
}

