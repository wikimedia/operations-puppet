# OSM role classes

class role::osm::common {
    include standard
}
class role::osm::master {
    include role::osm::common
    include postgresql::master
    include postgresql::postgis
    include passwords::osm
    postgres::spatialdb { 'gis': }

    if $osm_slave_v4 {
        postgresql::user { "replication@${::osm_slave}-v4":
            ensure   => 'present',
            user     => 'replication',
            password => $passwords::osm::replication_pass,
            cidr     => "${::osm_slave_v4}/32",
            type     => 'host',
            method   => 'md5',
            attrs    => 'REPLICATION',
            database => 'replication',
        }
    }
    if $osm_slave_v6 {
        postgresql::user { "replication@${::osm_slave}-v6":
            ensure   => 'present',
            user     => 'replication',
            password => $passwords::osm::replication_pass,
            cidr     => "${::osm_slave_v6}/128",
            type     => 'host',
            method   => 'md5',
            attrs    => 'REPLICATION',
            database => 'replication',
        }
    }
}

class role::osm::slave {
    include role::osm::common
    include postgresql::postgis
    include passwords::osm
    # Note: This is here to illustrate the fact that the slave is expected to
    # have the same dbs as the master.
    #postgres::spatialdb { 'gis': }

    class {'postgresql::slave':
        master_server    => $osm_master,
        replication_pass => $passwords::osm::replication_pass,
    }
}
