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
    package { "postgresql-${pgversion}-postgis":
        ensure  => $ensure,
    }
}
