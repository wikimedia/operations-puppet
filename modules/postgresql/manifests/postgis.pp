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
        'buster' => 'postgresql-11-postgis-3',
    },
) {
    $postgis_packages = [
        $postgresql_postgis_package,
        "${postgresql_postgis_package}-scripts",
        'postgis',
    ]

    if debian::codename::eq('buster') {
        apt::package_from_component { 'postgis':
            component => 'component/postgis',
            packages  => $postgis_packages,
        }
    } else {
        package { $postgis_packages:
            ensure  => $ensure,
        }
    }
}
