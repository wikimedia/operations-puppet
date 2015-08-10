# Class: kartotherian
#
# This class installs and configures kartotherian
#
# While only being a thin wrapper around service::node, this class exists to
# accomodate future kartotherian needs that are not suited for the service module
# classes as well as conform to a de-facto standard of having a module for every
# service
class kartotherian() {

    $cassandra_kartotherian_user = hiera('cassandra::kartotherian_user')
    $cassandra_kartotherian_pass = hiera('cassandra::kartotherian_pass')
    $pgsql_kartotherian_user = hiera('postgresql::master::kartotherian_user')
    $pgsql_kartotherian_pass = hiera('postgresql::master::kartotherian_pass')

    service::node { 'kartotherian':
        port   => 4000,
        config => template('kartotherian/config.yaml.erb'),
    }
}
