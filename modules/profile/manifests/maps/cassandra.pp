# SPDX-License-Identifier: Apache-2.0
class profile::maps::cassandra(
    Boolean $cassandra_enable           = lookup('profile::maps::cassandra::enable', { 'default_value' => true }),
    String $cassandra_kartotherian_pass = lookup('profile::maps::cassandra::kartotherian_pass'),
    String $cassandra_tilerator_pass    = lookup('profile::maps::cassandra::tilerator_pass'),
    String $cassandra_tileratorui_pass  = lookup('profile::maps::cassandra::tileratorui_pass'),
){

    if $cassandra_enable {
        require profile::cassandra::single_instance

        file { '/usr/local/bin/maps-grants.cql':
            owner   => 'root',
            group   => 'root',
            mode    => '0400',
            content => template('profile/maps/grants.cql.erb'),
        }
    }
}
