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
    $ensure='present',
    $pgversion = $::lsbdistcodename ? {
        jessie  => '9.4',
        precise => '9.1',
        trusty  => '9.3',
    },
    ) {

    ferm::service { 'postgres-postgis':
        proto  => 'tcp',
        port   => 5432,
        srange => '$INTERNAL',
    }

    package { [
                "postgresql-${pgversion}-postgis",
                "postgresql-contrib-${pgversion}",
                'postgis',
            ]:
        ensure  => $ensure,
    }
}
