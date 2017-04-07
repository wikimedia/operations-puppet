class profile::maps::cassandra(
    $cassandra_kartotherian_pass = hiera('profile::maps::cassandra::kartotherian_pass'),
    $cassandra_tilerator_pass = hiera('profile::maps::cassandra::tilerator_pass'),
    $cassandra_tileratorui_pass = hiera('profile::maps::cassandra::tileratorui_pass'),
) {
    require profile::cassandra::single_instance

    file { '/usr/local/bin/maps-grants.cql':
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        content => template('profile/maps/grants.cql.erb'),
    }
}