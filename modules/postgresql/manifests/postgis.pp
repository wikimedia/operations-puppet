# Class: postgresql::postgis
#
# This class installs postgis packages
#
# Parameters:
#
# Actions:
#     Install postgis
#
# Requires:
#
# Sample Usage:
#     include postgresql::postgis
#
class postgresql::postgis(
                        $pgversion='9.1',
                        $ensure='present'
                        ) {
    Class['postgresql::server'] -> Class['postgresql::postgis']

    class { 'postgresql::server':
        ensure    => $ensure,
        pgversion => $pgversion,
    }

    package { "postgresql-${pgversion}-postgis":
        ensure  => $ensure,
    }
}
