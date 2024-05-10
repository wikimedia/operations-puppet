# SPDX-License-Identifier: Apache-2.0

# geoip requires an account / license keys for free versions as well download
# the test geoip2-city database instead to make things work of out the box by
# default

# XXX refactor in sth like geoip::data::maxmind::test
class pontoon::geoip (
    Stdlib::Unixpath $base_dir,
    Array[String] $product_ids = [
        'GeoIP2-City',
        'GeoIP2-Connection-Type',
    ],
) {
    $product_ids.each |$db| {
        $db_path = "${base_dir}/${db}.mmdb"
        $db_url = "https://github.com/maxmind/MaxMind-DB/raw/main/test-data/${db}-Test.mmdb"
        wmflib::dir::mkdir_p($db_path.dirname)

        exec { "download test db ${db}":
            creates => $db_path,
            command => "/usr/bin/wget -O ${db_path} ${db_url}",
        }
    }
}
