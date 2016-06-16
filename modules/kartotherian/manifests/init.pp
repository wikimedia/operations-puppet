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
# [*contact_groups*]
#   Contact groups for alerting.
#   Default: 'admins'
#
class kartotherian(
    $conf_sources   = 'sources.prod.yaml',
    $contact_groups = 'admins',
) {

    $cassandra_kartotherian_user = 'kartotherian'
    $cassandra_kartotherian_pass = hiera('maps::cassandra_kartotherian_pass')
    $pgsql_kartotherian_user = 'kartotherian'
    $pgsql_kartotherian_pass = hiera('maps::postgresql_kartotherian_pass')

    service::node { 'kartotherian':
        port            => 6533,
        config          => template('kartotherian/config.yaml.erb'),
        deployment      => 'scap3',
        has_spec        => true,
        healthcheck_url => '',
        contact_groups  => $contact_groups,
    }
}
