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
        'stretch' => 'postgresql-9.6-postgis-2.3',
        'jessie'  => 'postgresql-9.4-postgis-2.3',
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
