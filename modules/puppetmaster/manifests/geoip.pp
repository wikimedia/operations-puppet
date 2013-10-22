class puppetmaster::geoip {
    include passwords::geoip
    # Including geoip with data_provider => maxmind will install a
    # cron job to download GeoIP data files from Maxmind weekly.
    # Setting data_directory will have those files downloaded into
    # data_directory.  By downloading these files into the
    # volatiledir they will be available for other nodes to get via
    # puppet by including geoip with data_provider => 'puppet'.

    # Sigh, need to manually include ::geoip::data here, since we are
    # changing data_directory and puppet class inheritance with parameters
    # is funky.
    class { '::geoip::data':
        data_directory => "${puppetmaster::volatiledir}/GeoIP",
    }
    class { '::geoip':
        data_provider  => 'maxmind',
        data_directory => "${puppetmaster::volatiledir}/GeoIP",
        environment    => 'http_proxy=http://brewster.wikimedia.org:8080',  # use brewster as http proxy, since puppetmaster probably does not have internet access
        license_key    => $passwords::geoip::license_key,
        user_id        => $passwords::geoip::user_id,
        product_ids    => [106, 133, 115],
    }
}
