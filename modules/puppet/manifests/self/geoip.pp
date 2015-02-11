class puppet::self::geoip {
    # FIXME: this a partial duplicate of puppetmaster::geoip

    $geoip_destdir = '/var/lib/puppet/volatile/GeoIP'

    # geoip::data classes depend on this
    file { $geoip_destdir:
        ensure => directory,
    }

    # legacy; remove eventually
    file { '/usr/local/bin/geoliteupdate':
        ensure => absent,
    }
    cron { 'geoliteupdate':
        ensure => absent,
    }

    class { 'geoip::data::maxmind':
        data_directory => $geoip_destdir,
        product_ids    => [
            '506', # GeoLite Legacy Country
            '517', # GeoLite ASN
            '533', # GeoLite Legacy City
            'GeoLite2-Country',
            'GeoLite2-City',
            ],
    }

    # compatibility symlinks, so that users can use the stable paths
    # GeoIP.dat/GeoIPCity.dat between labs and production
    file { "${geoip_destdir}/GeoIP.dat":
        ensure => link,
        target => 'GeoLiteCountry.dat',
    }
    file { "${geoip_destdir}/GeoIPCity.dat":
        ensure => link,
        target => 'GeoLiteCity.dat',
    }
    file { "${geoip_destdir}/GeoIP2-Country.mmdb":
        ensure => link,
        target => 'GeoLite2-Country.mmdb',
    }
    file { "${geoip_destdir}/GeoIP2-City.mmdb":
        ensure => link,
        target => 'GeoLite2-City.mmdb',
    }
}
