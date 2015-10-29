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

    # NOTE: The port here is only used for health monitoring. tilerator is a
    # daemon executing tasks from a queue, it does not realy listen to requests.
    # So there will never be LVS or anything else than health check requests to
    # this port
    service::node { 'tilerator':
        port       => 6534,
        config     => template('tilerator/config.yaml.erb'),
        no_workers => $::processorcount / 2,
    }
}
