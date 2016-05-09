#

class osm {

    # osm2pgsql 0.90 is only available on jessie at the moment
    # there is no need for 0.90 on labs machines (precise)
    if $::lsbdistcodename == 'jessie' {
        # Can't use require_package here because we need to specify version
        # from jessie-backports:
        if !defined(Package['osm2pgsql']) {
            package { 'osm2pgsql':
                ensure => '0.90.0+ds-1~bpo8+1',
            }
        }
    } else {
        require_package('osm2pgsql')
    }

    require_package('osmosis')
}
