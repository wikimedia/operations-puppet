class puppetmaster::geoip {
    # Fetch the GeoIP databases into puppet's volatile dir, so that other hosts
    # can then just sync that directory into their own /usr/share/GeoIP via a
    # normal puppet File resource (see the geoip module for more)

    $geoip_destdir = "${puppetmaster::volatiledir}/GeoIP"
    $environment = 'http_proxy=http://carbon.wikimedia.org:8080'

    # geoip::data classes depend on this
    file { $geoip_destdir:
        ensure => directory,
    }

    # fetch the GeoLite databases
    class { 'geoip::data::lite':
        data_directory => $geoip_destdir,
        environment    => $environment,
    }

    if $is_labs_puppet_master {
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
    } else {
        # Fetch the proprietary paid-for MaxMind database
        include passwords::geoip

        class { 'geoip::data::maxmind':
            data_directory => $geoip_destdir,
            environment    => $environment,
            license_key    => $passwords::geoip::license_key,
            user_id        => $passwords::geoip::user_id,
            product_ids    => [106, 133, 115],
        }
    }
}
