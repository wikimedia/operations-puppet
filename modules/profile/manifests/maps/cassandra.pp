class profile::maps::cassandra(
    String $cassandra_kartotherian_pass = lookup('profile::maps::cassandra::kartotherian_pass'),
    String $cassandra_tilerator_pass    = lookup('profile::maps::cassandra::tilerator_pass'),
    String $cassandra_tileratorui_pass  = lookup('profile::maps::cassandra::tileratorui_pass'),
){

    require profile::cassandra::single_instance

    file { '/usr/local/bin/maps-grants.cql':
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        content => template('profile/maps/grants.cql.erb'),
    }
}
