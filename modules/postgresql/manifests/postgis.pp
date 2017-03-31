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
    $ensure = 'present',
    $postgresql_postgis_package = $::lsbdistcodename ? {
        'jessie'  => 'postgresql-9.4-postgis-2.3',
        'trusty'  => 'postgresql-9.3-postgis-2.1',
    },
) {
    package { [
        $postgresql_postgis_package,
        "${postgresql_postgis_package}-scripts",
        'postgis',
    ]:
        ensure  => $ensure,
    }
}
