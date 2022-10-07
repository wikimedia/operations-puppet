# SPDX-License-Identifier: Apache-2.0
class profile::maps::osm_master (
    String $planet_sync_period                   = lookup('profile::maps::osm_master::planet_sync_period', { 'default_value' => 'hour' }),
    String $planet_sync_day                      = lookup('profile::maps::osm_master::planet_sync_day', { 'default_value' => '*' }),
    Variant[String,Integer]$planet_sync_hours    = lookup('profile::maps::osm_master::planet_sync_hours', { 'default_value' => '*' }),
    Variant[String,Integer] $planet_sync_minute  = lookup('profile::maps::osm_master::planet_sync_minute', { 'default_value' => '00' }),
    Array[Stdlib::Host] $maps_hosts              = lookup('profile::maps::hosts'),
    String $kartotherian_pass                    = lookup('profile::maps::osm_master::kartotherian_pass'),
    String $tilerator_pass                       = lookup('profile::maps::osm_master::tilerator_pass'),
    String $tileratorui_pass                     = lookup('profile::maps::osm_master::tileratorui_pass'),
    String $replication_pass                     = lookup('profile::maps::osm_master::replication_pass'),
    String $swift_key_id                         = lookup('profile::maps::osm_master::swift_key_id'),
    String $swift_password                       = lookup('profile::maps::osm_master::swift_password'),
    String $tegola_swift_container               = lookup('profile::maps::osm_master::tegola_swift_container'),
    Hash[String, Struct[{ip_address => Stdlib::IP::Address}]] $postgres_replicas = lookup('profile::maps::osm_master::replicas', { 'default_value' => {}}),
    String $osm_engine                           = lookup('profile::maps::osm_master::engine', { 'default_value' => 'osm2pgsql' }),
    Boolean $disable_replication_cron            = lookup('profile::maps::osm_master::disable_replication_cron', { 'default_value' => false }),
    Boolean $disable_tile_generation_cron        = lookup('profile::maps::osm_master::disable_tile_generation_cron', { 'default_value' => false }),
    Boolean $disable_admin_timer                 = lookup('profile::maps::osm_master::disable_admin_timer', { 'default_value' => false }),
    String $tilerator_storage_id                 = lookup('profile::maps::apps::tilerator_storage_id'),
    Boolean $use_proxy                           = lookup('profile::maps::apps::use_proxy'),
    String $eventgate_endpoint                         = lookup('profile::maps::osm_master::eventgate_endpoint'),
    Optional[Integer[250]] $log_min_duration_statement = lookup('profile::maps::osm_master::log_min_duration_statement', { 'default_value' => undef })
) {

    require profile::maps::postgresql_common
    include network::constants

    $tegola_networks = flatten([
        $network::constants::services_kubepods_networks,
        $network::constants::staging_kubepods_networks,
    ])

    $maps_hosts_ferm = join($maps_hosts, ' ')

    $db_name = 'gis'

    $pgversion = $::lsbdistcodename ? {
        'bullseye'  => 13,
        'buster'  => 11,
    }

    # We need 1 connection per host that is fully pooled. If we want
    # to pool additional hosts, we need TWO connections per host (one
    # for the backup thread, and one for the streaming of new logs
    # thread). 6 will give us the overhead to allow for 3 new hosts to
    # be added at once in case we need this.
    $max_senders = length($maps_hosts) + 6

    class { 'postgresql::master':
        root_dir                   => '/srv/postgresql',
        includes                   => [ 'tuning.conf', 'logging.conf' ],
        checkpoint_segments        => 768,
        wal_keep_segments          => 768,
        max_wal_senders            => $max_senders,
        log_min_duration_statement => $log_min_duration_statement,
    }

    class { '::osm': }
    class { '::osm::import_waterlines':
        use_proxy  => $use_proxy,
        proxy_host => "webproxy.${::site}.wmnet",
        proxy_port => 8080,
    }

    # Users
    postgresql::user { 'kartotherian':
        user     => 'kartotherian',
        password => $kartotherian_pass,
        database => $db_name,
    }
    postgresql::user { 'tileratorui':
        user     => 'tileratorui',
        password => $tileratorui_pass,
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

    profile::maps::tilerator_user { 'localhost':
        ip_address => '127.0.0.1/32',
        password   => $tilerator_pass,
    }
    # tegola-vector-tiles will connect as user tilerator from
    # kubernetes pods.
    $tegola_networks.each |String $subnet| {
        if $subnet =~ Stdlib::IP::Address::V4 {
            $_subnet = split($subnet, '/')[0]
            profile::maps::tilerator_user { "${_subnet}_kubepod":
            ip_address => $subnet,
            password   => $tilerator_pass,
            }
        }
    }

    if $postgres_replicas {
        create_resources(
            profile::maps::tilerator_user,
            $postgres_replicas,
            { password => $tilerator_pass }
        )
    }

    # Grants
    file { "/usr/local/bin/maps-grants-${db_name}.sql":
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        content => template('profile/maps/grants-db.sql.erb'),
    }
    file { '/usr/local/bin/maps-grants-tiles.sql':
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        content => template('profile/maps/grants-tiles.sql.erb'),
    }

    # DB setup
    postgresql::spatialdb { $db_name: }

    # some additional logging for the postgres master to help diagnose import
    # performance issues
    file { "/etc/postgresql/${pgversion}/main/logging.conf":
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/profile/maps/logging.conf',
    }

    file { '/root/.tegola_credentials':
        ensure  => 'present',
        mode    => '0600',
        owner   => 'root',
        group   => 'root',
        content => template('profile/maps/swift_config.erb'),
    }

    if $postgres_replicas {
        $postgres_replicas_defaults = {
            replication_pass => $replication_pass,
        }
        create_resources(postgresql::slave_users, $postgres_replicas, $postgres_replicas_defaults)
    }

    sudo::user { 'tilerator-notification':
        user       => 'osmupdater',
        privileges => [
            'ALL = (tileratorui) NOPASSWD: /usr/local/bin/notify-tilerator',
        ],
    }

    osm::planet_sync { $db_name:
        ensure                       => present,
        engine                       => $osm_engine,
        flat_nodes                   => true,
        expire_levels                => 15,
        num_threads                  => 4,
        use_proxy                    => $use_proxy,
        proxy_host                   => "webproxy.${::site}.wmnet",
        proxy_port                   => 8080,
        period                       => $planet_sync_period,
        day                          => $planet_sync_day,
        hours                        => $planet_sync_hours,
        minute                       => $planet_sync_minute,
        postreplicate_command        => '/usr/local/bin/notify-tilerator',
        postreplicate_user           => 'tileratorui',
        disable_replication_cron     => $disable_replication_cron,
        disable_tile_generation_cron => $disable_tile_generation_cron,
        eventgate_endpoint           => $eventgate_endpoint,
        swift_key_id                 => $swift_key_id,
        swift_password               => $swift_password,
        tegola_swift_container       => $tegola_swift_container
    }

    if ($osm_engine == 'osm2pgsql') {
        file { '/usr/local/bin/grants-populate-admin.sql':
            owner  => 'postgres',
            group  => 'postgres',
            mode   => '0400',
            source => 'puppet:///modules/profile/maps/grants-populate-admin.sql',
        }
        osm::populate_admin { $db_name:
            ensure              => present,
            disable_admin_timer => $disable_admin_timer,
        }
    }

    class { 'tilerator::regen':
        storage_id => $tilerator_storage_id,
    }

    $state_path = $osm_engine ? {
        'imposm3' => '/srv/osm/diff/last.state.txt',
        'osm2pgsql' => '/srv/osmosis/state.txt'
    }

    class { 'osm::prometheus':
        state_path      => $state_path,
        prometheus_path => '/var/lib/prometheus/node.d/osm_sync_lag.prom',
    }

    # Access to postgres master from postgres replicas
    ferm::service { 'postgres_maps':
        proto  => 'tcp',
        port   => '5432',
        srange => "@resolve((${maps_hosts_ferm}))",
    }

    # Enable venvs for ad-hoc python scripts
    ensure_packages('python3-venv')

    # Install kafkacat and python libs to interract with kafka for dev/debug reasons
    ensure_packages(['kafkacat', 'python3-kafka', 'python3-snappy'])

    # Install dependencies to interract with swift storage
    ensure_packages(['swift', 'python3-swiftclient', 's3cmd', 'python3-boto'])

    # T290982
    ensure_packages('python3-maps-deduped-tilelist')
}
