# Class: mapsadminui
#
# This class installs and configures mapsadminui
#
# While only being a thin wrapper around service::node, this class exists to
# accomodate future mapsadminui needs that are not suited for the service module
# classes as well as conform to a de-facto standard of having a module for every
# service
class mapsadminui {
    $cassandra_mapsadminui_user = 'mapsadminui'
    $cassandra_mapsadminui_pass = hiera('maps::cassandra_mapsadminui_pass')
    $pgsql_mapsadminui_user = 'mapsadminui'
    $pgsql_mapsadminui_pass = hiera('maps::postgresql_mapsadminui_pass')

    # NOTE: mapsadminui does not have an LVS service associated with it. It is
    # only meant to be used through an SSH tunnel
    service::node { 'mapsadminui':
        port       => 6535,
        config     => template('mapsadminui/config.yaml.erb'),
        no_workers => 0, # 0 on purpose to only have one instance running
    }
}
