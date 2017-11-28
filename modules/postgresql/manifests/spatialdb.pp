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

    postgresql::db { $title:
        ensure => $ensure,
        owner  => $owner,
    }

    postgresql::db::extension { "${title}-postgis":
        ensure   => $ensure,
        database => $title,
        extname  => 'postgis',
        require  => Postgresql::Db[$title],
    }
    postgresql::db::extension { "${title}-hstore":
        ensure   => $ensure,
        database => $title,
        extname  => 'hstore',
        require  => Postgresql::Db[$title],
    }

}
