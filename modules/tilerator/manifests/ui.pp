# Class: tilerator::ui
#
# This class installs and configures tilerator::ui
#
# While only being a thin wrapper around service::node, this class exists to
# accomodate future tileratorui needs that are not suited for the service module
# classes as well as conform to a de-facto standard of having a module for every
# service
class tilerator::ui {
    $cassandra_tileratorui_user = 'tileratorui'
    $cassandra_tileratorui_pass = hiera('maps::cassandra_tileratorui_pass')
    $pgsql_tileratorui_user = 'tileratorui'
    $pgsql_tileratorui_pass = hiera('maps::postgresql_tileratorui_pass')

    # NOTE: tileratorui does not have an LVS service associated with it. It is
    # only meant to be used through an SSH tunnel
    service::node { 'tileratorui':
        port       => 6535,
        config     => template('tilerator/config_ui.yaml.erb'),
        no_workers => 0, # 0 on purpose to only have one instance running
        repo       => 'tilerator/deploy',
    }
}
