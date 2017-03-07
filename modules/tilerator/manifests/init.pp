# Class: tilerator
#
# This class installs and configures tilerator
#
# While only being a thin wrapper around service::node, this class exists to
# accomodate future tilerator needs that are not suited for the service module
# classes as well as conform to a de-facto standard of having a module for every
# service
#
# === Parameters
#
# [*conf_sources*]
#   Sources that will be added to the configuration file of the service. This
#   defines the data transformation pipeline for the tile services. The actual
#   file is loaded from the root of the source code directory.
#   (/srv/deployment/tilerator/deploy/src/)
#   Default: 'sources.prod.yaml'
#
# [*contact_groups*]
#   Contact groups for alerting.
#   Default: 'admins'
#
# [*cassandra_servers*]
#   List of cassandra server names used by Tilerator
#
class tilerator(
    $cassandra_pass,
    $pgsql_pass,
    $redis_server,
    $cassandra_servers,
    $conf_sources      = 'sources.prod.yaml',
    $contact_groups    = 'admins',
    $deployment        = 'scap3',
) {

    validate_array($cassandra_servers)

    $cassandra_user = 'tilerator'
    $pgsql_user = 'tilerator'

    # NOTE: The port here is only used for health monitoring. tilerator is a
    # daemon executing tasks from a queue, it does not realy listen to requests.
    # So there will never be LVS or anything else than health check requests to
    # this port
    service::node { 'tilerator':
        port              => 6534,
        deployment_config => true,
        no_workers        => $::processorcount / 2,
        deployment        => $deployment,
        deployment_vars   => {
            entrypoint         => '""',
            conf_sources       => $conf_sources,
            cassandra_user     => $cassandra_user,
            cassandra_password => $cassandra_pass,
            cassandra_servers  => $cassandra_servers,
            osmdb_user         => $pgsql_user,
            osmdb_password     => $pgsql_pass,
            redis_server       => $redis_server,
            ui_only            => false,
            daemon_only        => true,
        },
        contact_groups    => $contact_groups,
    }

}
