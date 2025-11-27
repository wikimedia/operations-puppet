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
        'bookworm' => 'postgresql-15-postgis-3',
    },
) {
    $postgis_packages = [
        $postgresql_postgis_package,
        "${postgresql_postgis_package}-scripts",
        'postgis',
    ]

    ensure_packages($postgis_packages)
}
