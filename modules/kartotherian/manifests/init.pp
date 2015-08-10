# Class: kartotherian
#
# This class installs and configures kartotherian
#
# While only being a thin wrapper around service::node, this class exists to
# accomodate future kartotherian needs that are not suited for the service module
# classes as well as conform to a de-facto standard of having a module for every
# service
class kartotherian() {


    # TODO: Switch to these passwords: non-default cassandra, and dedicated postgresql for kartotherian
#    $cassandra_kartotherian_user = 'cassandra'
#    $cassandra_kartotherian_pass = hiera('cassandra::kartotherian_pass')
#    $pgsql_kartotherian_user = 'kartotherian'
#    $pgsql_kartotherian_pass = hiera('postgresql::master::kartotherian_pass')

    # TODO: Remove these once above are ready
    # For now, using tilerator pgsql account is ok because it has identical rights (read-only db access)
    $cassandra_kartotherian_user = 'cassandra'
    $cassandra_kartotherian_pass = 'cassandra'
    $pgsql_kartotherian_user = 'tilerator'
    $pgsql_kartotherian_pass = hiera('postgresql::master::tilerator_pass')

    service::node { 'kartotherian':
        port   => 4000,
        config => template('kartotherian/config.yaml.erb'),
    }
}
