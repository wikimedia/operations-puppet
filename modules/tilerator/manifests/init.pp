# Class: tilerator
#
# This class installs and configures tilerator
#
# While only being a thin wrapper around service::node, this class exists to
# accomodate future tilerator needs that are not suited for the service module
# classes as well as conform to a de-facto standard of having a module for every
# service
class tilerator() {

    $cassandra_tilerator_user = 'tilerator'
    $cassandra_tilerator_pass = hiera('maps::cassandra_tilerator_pass')
    $pgsql_tilerator_user = 'tilerator'
    $pgsql_tilerator_pass = hiera('maps::postgresql_tilerator_pass')

    # NOTE: We are explicitly not passing a port argument here. tilerator is a
    # daemon executing tasks from a queue, it does not listen to requests
    service::node { 'tilerator':
        config     => template('tilerator/config.yaml.erb'),
        no_workers => $::processorcount / 2,
    }
}
