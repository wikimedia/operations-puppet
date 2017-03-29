#
# Definition: postgresql::spatialdb
#
# This definition provides a way to manage spatial dbs
#
# Parameters:
#
# Actions:
#   Create/drop database
#
# Requires:
#   Class['postgresql::postgis']
#
# Sample Usage:
#  postgresql::spatialdb { 'mydb': }
#
define postgresql::spatialdb(
    $ensure = 'present',
    $owner  = 'postgres',
) {

    require ::postgresql::postgis

    postgresql::db { $name:
        ensure => $ensure,
        owner  => $owner,
    }

    postgresql::extension { "${name}-postgis":
        ensure   => $ensure,
        database => $name,
        extname  => 'postgis',
        require  => Postgresql::Db[$name],
    }
    postgresql::extension { "${name}-hstore":
        ensure   => $ensure,
        database => $name,
        extname  => 'postgis',
        require  => Postgresql::Db[$name],
    }

}
