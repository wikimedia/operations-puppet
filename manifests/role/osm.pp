# OSM role classes

class role::osm::master {
    include postgresql::master
    include postgresql::postgis
    include passwords::osm

    if $::osm_slave_v4 {
        postgresql::user { "replication@${::osm_slave}-v4":
            ensure   => 'present',
            user     => 'replication',
            password => $passwords::osm::replication_pass,
            cidr     => "${::osm_slave_v4}/32",
            type     => 'host',
            method   => 'md5',
            attrs    => 'REPLICATION',
            database => 'replication',
            require  => Class['postgresql::master'],
        }
    }
    if $::osm_slave_v6 {
        postgresql::user { "replication@${::osm_slave}-v6":
            ensure   => 'present',
            user     => 'replication',
            password => $passwords::osm::replication_pass,
            cidr     => "${::osm_slave_v6}/128",
            type     => 'host',
            method   => 'md5',
            attrs    => 'REPLICATION',
            database => 'replication',
            require  => Class['postgresql::master'],
        }
    }
}

class role::osm::slave {
    include postgresql::postgis
    include passwords::osm

    class {'postgresql::slave':
        master_server    => $::osm_master,
        replication_pass => $passwords::osm::replication_pass,
    }
}
