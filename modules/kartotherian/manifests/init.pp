# Class: kartotherian
#
# This class installs and configures kartotherian
#
# While only being a thin wrapper around service::node, this class exists to
# accomodate future kartotherian needs that are not suited for the service module
# classes as well as conform to a de-facto standard of having a module for every
# service
#
# === Parameters
#
# [*conf_sources*]
#   Sources that will be added to the configuration file of the service. This
#   defines the data transformation pipeline for the tile services. The actual
#   file is loaded from the root of the source code directory.
#   (/srv/deployment/kartotherian/deploy/src/)
#   Default: 'sources.prod.yaml'
#
# [*contact_groups*]
#   Contact groups for alerting.
#   Default: 'admins'
#
# [*cassandra_servers*]
#   List of cassandra server names used by Kartotherian
#
class kartotherian(
    $cassandra_servers,
    $cassandra_kartotherian_pass,
    $pgsql_kartotherian_pass,
    $conf_sources      = 'sources.prod.yaml',
    $keyspace          = 'v3',
    $contact_groups    = 'admins',
    $port              = 6533,
    $num_workers       = 'ncpu',
    $cassandra_kartotherian_user = 'kartotherian',
    $pgsql_kartotherian_user = 'kartotherian',
) {

    validate_array($cassandra_servers)

    ensure_packages(['libmapnik3.0'])

    service::node { 'kartotherian':
        port              => $port,
        deployment        => 'scap3',
        deployment_config => true,
        deployment_vars   => {
            geoshapes_user     => $pgsql_kartotherian_user,
            geoshapes_password => $pgsql_kartotherian_pass,
            conf_sources       => $conf_sources,
            keyspace           => $keyspace,
            cassandra_user     => $cassandra_kartotherian_user,
            cassandra_password => $cassandra_kartotherian_pass,
            cassandra_servers  => $cassandra_servers,
            osmdb_password     => $pgsql_kartotherian_pass,
            osmdb_user         => $pgsql_kartotherian_user,
        },
        has_spec          => true,
        healthcheck_url   => '',
        contact_groups    => $contact_groups,
    }
}
