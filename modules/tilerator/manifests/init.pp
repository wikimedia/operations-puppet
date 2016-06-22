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
# [*expmask*]
#   regex to match expiration files
#   used in Tilerator notification
#
# [*statefile*]
#   tilerator uses this file to record last imported data file
#   used in Tilerator notification
#
# [*from_zoom*]
#   new jobs will be created from this zoom
#   used in Tilerator notification
#
# [*before_zoom*]
#   and until (but not including) this zoom
#   used in Tilerator notification
#
# [*generator_id*]
#   copy tiles from ("gen" will only produce non-empty tiles)
#   used in Tilerator notification
#
# [*storage_id*]
#   copy tiles to
#   used in Tilerator notification
#
# [*delete_empty*]
#   if tile is empty, make sure we don't store it, if it was there before
#   used in Tilerator notification
#
class tilerator(
    $conf_sources   = 'sources.prod.yaml',
    $contact_groups = 'admins',
    $expmask        = 'expire\\.list\\.*',
    $statefile      = '/srv/osm_expire/expire.state',
    $from_zoom      = 10,
    $before_zoom    = 16,
    $generator_id   = 'gen',
    $storage_id     = 'v3',
    $delete_empty   = 1,
) {
    include ::tilerator::ui

    $cassandra_tilerator_user = 'tilerator'
    $cassandra_tilerator_pass = hiera('maps::cassandra_tilerator_pass')
    $pgsql_tilerator_user = 'tilerator'
    $pgsql_tilerator_pass = hiera('maps::postgresql_tilerator_pass')
    $redis_server = hiera('maps::redis_server')

    # NOTE: The port here is only used for health monitoring. tilerator is a
    # daemon executing tasks from a queue, it does not realy listen to requests.
    # So there will never be LVS or anything else than health check requests to
    # this port
    service::node { 'tilerator':
        port           => 6534,
        config         => template('tilerator/config.yaml.erb'),
        no_workers     => $::processorcount / 2,
        deployment     => 'scap3',
        contact_groups => $contact_groups,
    }

    file { '/usr/local/bin/notify-tilerator':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        content => template('osm/notify-tilerator.erb'),
    }

}
