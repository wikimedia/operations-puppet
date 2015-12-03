class puppetmaster::geoip(
    $fetch_private = true,
    $use_proxy = true,
) {
    # Fetch the GeoIP databases into puppet's volatile dir, so that other hosts
    # can then just sync that directory into their own /usr/share/GeoIP via a
    # normal puppet File resource (see the geoip module for more)

    $geoip_destdir = "${puppetmaster::volatiledir}/GeoIP"

    # geoip::data classes depend on this
    file { $geoip_destdir:
        ensure => directory,
    }

    if $use_proxy {
        $webproxy = "http://webproxy.${::site}.wmnet:8080"
    } else {
        $webproxy = undef
    }

    if $fetch_private {
        # Fetch the proprietary paid-for MaxMind database
        include passwords::geoip

        class { 'geoip::data::maxmind':
            data_directory => $geoip_destdir,
            proxy          => $webproxy,
            user_id        => $passwords::geoip::user_id,
            license_key    => $passwords::geoip::license_key,
            product_ids    => [
                '106', # GeoIP.dat
                '115', # GeoIPRegion.dat
                '132', # GeoIPCity.dat
                '133', # GeoIPCity.dat
                '171', # GeoIPNetSpeed.dat
                '177', # GeoIPNetSpeedCell.dat
                'GeoIP2-City',
                'GeoIP2-Connection-Type',
                'GeoIP2-Country',
                ],
        }
    } else {
        class { 'geoip::data::maxmind':
            data_directory => $geoip_destdir,
            proxy          => $webproxy,
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
}
