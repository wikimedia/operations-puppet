# SPDX-License-Identifier: Apache-2.0
class profile::maps::osm_master (
    String $planet_sync_period                   = lookup('profile::maps::osm_master::planet_sync_period', { 'default_value' => 'hour' }),
    String $planet_sync_day                      = lookup('profile::maps::osm_master::planet_sync_day', { 'default_value' => '*' }),
    Variant[String,Integer]$planet_sync_hours    = lookup('profile::maps::osm_master::planet_sync_hours', { 'default_value' => '*' }),
    Variant[String,Integer] $planet_sync_minute  = lookup('profile::maps::osm_master::planet_sync_minute', { 'default_value' => '00' }),
    Array[Stdlib::Host] $maps_hosts              = lookup('profile::maps::hosts'),
    String $kartotherian_pass                    = lookup('profile::maps::osm_master::kartotherian_pass'),
    String $tegola_pass                          = lookup('profile::maps::osm_master::tegola_pass'),
    String $replication_pass                     = lookup('profile::maps::osm_master::replication_pass'),
    String $swift_key_id                         = lookup('profile::maps::osm_master::swift_key_id'),
    String $swift_password                       = lookup('profile::maps::osm_master::swift_password'),
    String $tegola_swift_container               = lookup('profile::maps::osm_master::tegola_swift_container'),
    Hash[String, Struct[{ip_address => Stdlib::IP::Address}]] $postgres_replicas = lookup('profile::maps::osm_master::replicas', { 'default_value' => {}}),
    Boolean $disable_replication_timer           = lookup('profile::maps::osm_master::disable_replication_timer'),
    Boolean $disable_waterlines_import_timer     = lookup('profile::maps::osm_master::disable_waterlines_import_timer'),
    Boolean $enable_tile_invalidation            = lookup('profile::maps::osm_master::enable_tile_invalidation'),
    Boolean $use_proxy                           = lookup('profile::maps::apps::use_proxy'),
    String $eventgate_endpoint                         = lookup('profile::maps::osm_master::eventgate_endpoint'),
    Optional[Integer[250]] $log_min_duration_statement = lookup('profile::maps::osm_master::log_min_duration_statement', { 'default_value' => undef }),
    Boolean $use_replication_slots               = lookup('profile::maps::osm_master::use_replication_slots'),
    String $tiles_change_eventgate_stream        = lookup('profile::maps::osm_master::tiles_change_eventgate_stream', {'default_value' => 'maps.tiles_change'}),

) {

    require profile::maps::postgresql_common
    include network::constants

    $wikikube_networks = flatten([
        $network::constants::services_kubepods_networks,
        $network::constants::staging_kubepods_networks,
    ])

    $db_name = 'gis'
    $pgversion  = wmflib::debian_postgresql_version()

    $max_senders = 20 # Needs to be identical for master/replica role

    # We iterate through all maps hosts of the DC, and skip ourselves (master)
    $replication_slots = $use_replication_slots ? {
        true    => $maps_hosts.map |$replica| {
                    if $facts['networking']['fqdn'] != $replica {
                        "wal_${replica.regsubst('[\.-]', '_', 'G')}"
                    }
                    else {
                        undef
                    }
                }
                .filter |$replica| {
                        $replica != undef
                },
        default => [],
      }

    # All our ACLs are based on v4 IP. We should eventually move to FQDN-based
    # grants but in the interim only have postgresql listen on ipv4
    $listen_addresses = '0.0.0.0'

    class { 'postgresql::master':
        root_dir                   => '/srv/postgresql',
        includes                   => [ 'tuning.conf', 'logging.conf' ],
        checkpoint_segments        => 768,
        wal_keep_segments          => 768,
        max_wal_senders            => $max_senders,
        log_min_duration_statement => $log_min_duration_statement,
        replication_slots          => $replication_slots,
        listen_addresses           => $listen_addresses,
    }

    ensure_packages('osmosis')
    ensure_packages('osmium-tool')

    class { '::osm::import_waterlines':
        use_proxy                       => $use_proxy,
        proxy_host                      => "webproxy.${::site}.wmnet",
        proxy_port                      => 8080,
        disable_waterlines_import_timer => $disable_waterlines_import_timer,
    }

    # Users
    postgresql::user { 'kartotherian':
        user     => 'kartotherian',
        password => $kartotherian_pass,
        database => $db_name,
    }
    postgresql::user { 'osmimporter@localhost':
        user     => 'osmimporter',
        database => $db_name,
        type     => 'local',
        method   => 'peer'
    }
    postgresql::user { 'osmupdater@localhost':
        user     => 'osmupdater',
        database => $db_name,
        type     => 'local',
        method   => 'peer'
    }
    postgresql::user { 'prometheus@localhost':
        user     => 'prometheus',
        database => 'postgres',
        type     => 'local',
        method   => 'peer',
    }

    profile::maps::user_cidrs { 'tegola@localhost':
        user       => 'tegola',
        password   => $tegola_pass,
        database   => 'all',
        ip_address => '127.0.0.1/32',
    }

    # * tegola-vector-tiles will connect as user tilerator from
    #   kubernetes pods.
    # * kartotherian will connect from kubernetes pods.
    $wikikube_networks.each |String $subnet| {
        if $subnet =~ Stdlib::IP::Address::V4 {
            $_subnet = split($subnet, '/')[0]
            profile::maps::user_cidrs { "tegola@${_subnet}_kubepod":
                user       => 'tegola',
                database   => 'all',
                ip_address => $subnet,
                password   => $tegola_pass,
            }
            profile::maps::user_cidrs { "kartotherian@${_subnet}_kubepod":
                user       => 'kartotherian',
                database   => $db_name,
                ip_address => $subnet,
                password   => $kartotherian_pass,
            }
        }
    }

    file { '/etc/wikimedia/maps':
        ensure => directory,
        owner  => 'postgres',
        group  => 'postgres',
    }

    file { '/etc/wikimedia/maps/kartotherian':
        ensure  => file,
        owner   => 'postgres',
        mode    => '0600',
        content => $kartotherian_pass
    }

    file { '/etc/wikimedia/maps/tegola':
        ensure  => file,
        owner   => 'postgres',
        mode    => '0600',
        content => $tegola_pass
    }

    $postgres_replicas.each |$replica, $ip_address| {
        profile::maps::user_cidrs { "tegola@${replica}":
            user       => 'tegola',
            password   => $tegola_pass,
            database   => 'all',
            ip_address => $ip_address['ip_address'],
        }
    }

    $grants_file = 'profile/maps/grants-db-bookworm.sql.erb'

    file { "/usr/share/imposm/maps-grants-${db_name}.sql":
        mode    => '0444',
        content => template($grants_file),
    }

    # DB setup
    postgresql::spatialdb { $db_name: }

    # some additional logging for the postgres master to help diagnose import
    # performance issues
    file { "/etc/postgresql/${pgversion}/main/logging.conf":
        ensure => 'present',
        mode   => '0444',
        source => 'puppet:///modules/profile/maps/logging.conf',
    }

    file { '/root/.tegola_credentials':
        ensure  => 'present',
        mode    => '0600',
        content => template('profile/maps/swift_config.erb'),
    }

    if $postgres_replicas {
        $postgres_replicas_defaults = {
            replication_pass => $replication_pass,
        }
        create_resources(postgresql::slave_users, $postgres_replicas, $postgres_replicas_defaults)
    }

    osm::planet_sync { $db_name:
        ensure                        => present,
        expire_levels                 => 15,
        use_proxy                     => $use_proxy,
        proxy_host                    => "webproxy.${::site}.wmnet",
        proxy_port                    => 8080,
        period                        => $planet_sync_period,
        day                           => $planet_sync_day,
        hours                         => $planet_sync_hours,
        minute                        => $planet_sync_minute,
        disable_replication_timer     => $disable_replication_timer,
        enable_tile_invalidation      => $enable_tile_invalidation,
        eventgate_endpoint            => $eventgate_endpoint,
        swift_key_id                  => $swift_key_id,
        swift_password                => $swift_password,
        tegola_swift_container        => $tegola_swift_container,
        tiles_change_eventgate_stream => $tiles_change_eventgate_stream,
    }

    $state_path = '/srv/osm/diff/last.state.txt'

    class { 'osm::prometheus':
        state_path      => $state_path,
        prometheus_path => '/var/lib/prometheus/node.d/osm_sync_lag.prom',
    }

    # Access to postgres master from postgres replicas
    firewall::service { 'postgres_maps':
        proto  => 'tcp',
        port   => 5432,
        srange => $maps_hosts,
    }

    # Enable venvs for ad-hoc python scripts
    ensure_packages('python3-venv')

    # Install kcat and python libs to interract with kafka for dev/debug reasons
    ensure_packages(['kcat', 'python3-kafka', 'python3-snappy'])

    # Install dependencies to interract with swift storage
    ensure_packages(['swift', 'python3-swiftclient', 's3cmd', 'python3-boto'])

    # T290982
    ensure_packages('python3-maps-deduped-tilelist')
}
