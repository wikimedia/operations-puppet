# @summary Fetch the GeoIP databases into puppet's volatile dir, so that other hosts
#   can then just sync that directory into their own /usr/share/GeoIP via a
#   normal puppet File resource (see the geoip module for more)
# @param fetch_private Fetch the proprietary paid-for MaxMind database
# @param use_proxy fetch resources using the proxy
# @param ca_server the CA server to use
class puppetmaster::geoip(
    Boolean      $fetch_private = true,
    Boolean      $use_proxy     = true,
    Stdlib::Host $ca_server     = $facts['networking']['fqdn'],
){

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
        # FIXME: password classes should not be used within other modules
        include passwords::geoip # lint:ignore:wmf_styleguide

        class { 'geoip::data::maxmind':  # lint:ignore:wmf_styleguide
            data_directory => $geoip_destdir,
            proxy          => $webproxy,
            ca_server      => $ca_server,
            user_id        => $passwords::geoip::user_id,
            license_key    => $passwords::geoip::license_key,
            product_ids    => [
                'GeoIP2-City',
                'GeoIP2-Connection-Type',
                'GeoIP2-Country',
                'GeoIP2-ISP',
                ],
        }


        # T288844
        #
        # TODO: after I53708b14ed36c6ae0ca7d71df0fc704c60ab749b is merged, we can modify
        # accordingly to just include the freely available product_ids
        $geoip_destdir_ipinfo = "${puppetmaster::volatiledir}/GeoIPInfo"

        file { $geoip_destdir_ipinfo:
            ensure => directory,
        }
        # FIXME: modules should not use other modules directly
        class { 'geoip::data::maxmind::ipinfo': # lint:ignore:wmf_styleguide
            data_directory => $geoip_destdir_ipinfo,
            proxy          => $webproxy,
            ca_server      => $ca_server,
            user_id        => $passwords::geoip::user_id_ipinfo,
            license_key    => $passwords::geoip::license_key_ipinfo,
            product_ids    => [
                'GeoLite2-ASN',
                'GeoLite2-Country',
                'GeoLite2-City',
                ],
        }
    } else {
    # fall back to public legacy databases
        class { 'geoip::data::maxmind':  # lint:ignore:wmf_styleguide
            data_directory => $geoip_destdir,
            proxy          => $webproxy,
            product_ids    => [
                'GeoLite2-ASN',
                'GeoLite2-Country',
                'GeoLite2-City',
                ],
        }

        # If using public databases also install compatibility symlinks so that users
        # can use the stable paths GeoIP.dat/GeoIPCity.dat between labs and production
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
