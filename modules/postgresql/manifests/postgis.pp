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
        'precise' => 'postgresql-9.1-postgis',
        'trusty'  => 'postgresql-9.3-postgis-2.1',
    },
    $install_postgis_scripts = $::lsbdistcodename ? {
        'jessie'  => true,
        'precise' => false,
        'trusty'  => true,
        default   => true,
    },
) {
    validate_bool($install_postgis_scripts)

    package { [
        $postgresql_postgis_package,
        'postgis',
    ]:
        ensure  => $ensure,
    }

    if $install_postgis_scripts {
        package { "${postgresql_postgis_package}-scripts":
            ensure  => $ensure,
        }
    }
}
