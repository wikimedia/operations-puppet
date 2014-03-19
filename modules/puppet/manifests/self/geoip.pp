class puppet::self::geoip {
    # Fetch the GeoIP databases into puppet's volatile dir, so that other hosts
    # can then just sync that directory into their own /usr/share/GeoIP via a
    # normal puppet File resource (see the geoip module for more)

    $geoip_destdir = '/var/lib/git/volatile/GeoIP'
    $environment = 'http_proxy=http://brewster.wikimedia.org:8080'

    # geoip::data classes depend on this
    file { $geoip_destdir:
        ensure => directory,
    }

    # fetch the GeoLite databases
    class { 'geoip::data::lite':
        data_directory => $geoip_destdir,
        environment    => $environment,
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
}

