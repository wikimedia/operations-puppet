class puppetmaster::geoip {
    # Fetch the GeoIP databases into puppet's volatile dir, so that other hosts
    # can then just sync that directory into their own /usr/share/GeoIP via a
    # normal puppet File resource (see the geoip module for more)

    $geoip_destdir = "${puppetmaster::volatiledir}/GeoIP"
    $environment = 'http_proxy=http://brewster.wikimedia.org:8080'

    package { 'geoip-database':
        ensure => absent,
    }

    # installs the geoip-bin package
    class { '::geoip':
        data_provider  => undef,
    }

    # fetch the GeoLite databases
    class { 'geoip::data::lite':
        data_directory => $geoip_destdir,
        environment    => $environment,
    }

    if $::is_labs_puppet_master {
        # compatibility symlinks
        file { "$geoip_destdir/GeoIP.dat":
            ensure => link,
            target => "$geoip_destdir/GeoLite.dat",
        }
        file { "$geoip_destdir/GeoIPCity.dat":
            ensure => link,
            target => "$geoip_destdir/GeoLiteCity.dat",
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
