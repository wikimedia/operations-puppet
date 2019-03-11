# Class: tilerator::ui
#
# This class installs and configures tilerator::ui
#
# While only being a thin wrapper around service::node, this class exists to
# accomodate future tileratorui needs that are not suited for the service module
# classes as well as conform to a de-facto standard of having a module for every
# service
# NOTE: Tileratorui is a STATEFUL service. This is in contrast to all other
# services. It allows change of the configuration on the fly via the web
# interface. Specifically it is possible to change the sources as well as other
# parts of the configuration to allow insertion of jobs into the queue with
# different configuration (e.g. style) than the current one. It's been discussed
# that this needs to be revisited and done better in the future. It is rather
# innocuous right now as no users apart from an administrative user ever access
# it. tileratorui does not have an LVS service associated with it. It is
# only meant to be used through an SSH tunnel
# NOTE: The above is THE reason this service is separated from the tilerator
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
# [*port*]
#   Port on which tileratorui listen
#   Default: 6535
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
# [*osmosis_dir*]
#   directory in which osmosis keeps its state
#
# [*eventlogging_service_uri*]
#   URI for the eventbus service, for propagating resource change events
#   upon map tile (re)generation
#
# [*sources_to_invalidate*]
#   tile sources for which invalidation URIs will be generated. should be
#   kept in sync with the sources marked public in the Kartotherian prod
#   config
#
# [*tile_server_domain*]
#   domain of the tile server, to be used in generating invalidation URIs
#
class tilerator::ui(
    Array[String] $cassandra_servers,
    String $cassandra_pass,
    String $pgsql_pass,
    String $redis_server,
    String $redis_pass,
    Stdlib::Httpurl $eventlogging_service_uri,
    Array[String] $sources_to_invalidate,
    Stdlib::Fqdn $tile_server_domain,
    Stdlib::Port $port               = 6535,
    String  $contact_groups          = 'admins',
    Stdlib::Unixpath  $statefile_dir = '/var/run/tileratorui',
    Integer $from_zoom               = 10,
    Integer $before_zoom             = 16,
    String  $generator_id            = 'gen',
    String  $storage_id              = 'v3',
    Boolean $delete_empty            = true,
    Stdlib::Unixpath  $osmosis_dir   = '/srv/osmosis',
    Stdlib::Unixpath  $expire_dir    = '/srv/osm_expire/',
    Boolean $use_nodejs10            = false,
) {
    $statefile = "${statefile_dir}/expire.state"
    $cassandra_user = 'tileratorui'
    $pgsql_user = 'tileratorui'
    $redis_url = "${redis_server}?password=${redis_pass}"

    service::node { 'tileratorui':
        port              => $port,
        deployment_config => true,
        no_workers        => 0, # 0 on purpose to only have one instance running
        repo              => 'tilerator/deploy',
        deployment        => 'scap3',
        deployment_vars   => {
            entrypoint               => '""',
            cassandra_user           => $cassandra_user,
            cassandra_password       => $cassandra_pass,
            cassandra_servers        => $cassandra_servers,
            osmdb_user               => $pgsql_user,
            osmdb_password           => $pgsql_pass,
            redis_server             => $redis_url,
            ui_only                  => true,
            daemon_only              => false,
            storage_id               => $storage_id,
            eventlogging_service_uri => $eventlogging_service_uri,
            sources_to_invalidate    => $sources_to_invalidate,
            tile_server_domain       => $tile_server_domain,
        },
        contact_groups    => $contact_groups,
        use_nodejs10      => $use_nodejs10,
    }

    # HACK: service::node should add this sudo rule, but doesn't, because it deduplicates by repo name,
    # and tilerator uses the same repo name
    sudo::user { 'scap_deploy-service_tileratorui':
        user       => 'deploy-service',
        privileges => ['ALL=(root) NOPASSWD: /usr/sbin/service tileratorui *' ]
    }

    file { $statefile_dir:
        ensure => directory,
        owner  => 'tileratorui',
        group  => 'tileratorui',
        mode   => '0755',
    }

    file { '/usr/local/bin/notify-tilerator':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        content => template('tilerator/notify-tilerator.erb'),
    }

}
