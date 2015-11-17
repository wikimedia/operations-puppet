# == Class geoip::dev
# Installs the MaxMind library headers
#
class geoip::dev {
    package { [ 'libgeoip-dev', 'libmaxminddb-dev' ]:
        ensure => present,
    }
}
