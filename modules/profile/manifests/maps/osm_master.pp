class profile::maps::osm_master (
    String $planet_sync_period                  = lookup('profile::maps::osm_master::planet_sync_period', { 'default_value' => 'hour' }),
    String $planet_sync_day                     = lookup('profile::maps::osm_master::planet_sync_day', { 'default_value' => '*' }),
    Variant[String,Integer]$planet_sync_hours   = lookup('profile::maps::osm_master::planet_sync_hours', { 'default_value' => '*' }),
    Variant[String,Integer] $planet_sync_minute = lookup('profile::maps::osm_master::planet_sync_minute', { 'default_value' => 0 }),
    Array[Stdlib::Host] $maps_hosts             = lookup('profile::maps::hosts'),
    String $kartotherian_pass                   = lookup('profile::maps::osm_master::kartotherian_pass'),
    String $tilerator_pass                      = lookup('profile::maps::osm_master::tilerator_pass'),
    String $tileratorui_pass                    = lookup('profile::maps::osm_master::tileratorui_pass'),
    String $replication_pass                    = lookup('profile::maps::osm_master::replication_pass'),
    Hash[String, Struct[{ip_address => Stdlib::IP::Address}]] $postgres_replicas = lookup('profile::maps::osm_master::replicas', { 'default_value' => {}}),
    Boolean $cleartables                        = lookup('profile::maps::osm_master::cleartables', { 'default_value' => false }),
    Boolean $disable_replication_cron           = lookup('profile::maps::osm_master::disable_replication_cron', { 'default_value' => false }),
    Boolean $disable_admin_cron                 = lookup('profile::maps::osm_master::disable_admin_cron', { 'default_value' => false }),
    String $tilerator_storage_id                = lookup('profile::maps::apps::tilerator_storage_id'),
    Boolean $use_proxy                          = lookup('profile::maps::apps::use_proxy'),
) {

    require profile::maps::postgresql_common

    $maps_hosts_ferm = join($maps_hosts, ' ')

    $db_name = $cleartables ? {
        true    => 'ct',
        default => 'gis',
    }

    $pgversion = $::lsbdistcodename ? {
        'stretch' => 9.6,
    }

    class { 'postgresql::master':
        root_dir            => '/srv/postgresql',
        includes            => [ 'tuning.conf', 'logging.conf' ],
        checkpoint_segments => 768,
        wal_keep_segments   => 768,
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
        ip_address => '127.0.0.1',
        password   => $tilerator_pass,
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
    file { '/usr/local/bin/grants-populate-admin.sql':
        owner  => 'postgres',
        group  => 'postgres',
        mode   => '0400',
        source => 'puppet:///modules/profile/maps/grants-populate-admin.sql',
    }

    # DB setup
    postgresql::spatialdb { $db_name: }
    if $cleartables {
        postgresql::db::extension { "${db_name}-fuzzystrmatch":
          database => $db_name,
          extname  => 'fuzzystrmatch',
          require  => Postgresql::Db[$db_name],
        }
        postgresql::db::extension { "${db_name}-unaccent":
          database => $db_name,
          extname  => 'unaccent',
          require  => Postgresql::Db[$db_name],
        }
    }

    # some additional logging for the postgres master to help diagnose import
    # performance issues
    file { "/etc/postgresql/${pgversion}/main/logging.conf":
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/profile/maps/logging.conf',
    }

    file { '/usr/local/bin/osm-initial-import':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => 'puppet:///modules/profile/maps/osm-initial-import',
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

    if $cleartables {
        osm::cleartables_sync { $db_name:
            ensure                   => present,
            use_proxy                => $use_proxy,
            proxy_host               => "webproxy.${::site}.wmnet",
            proxy_port               => 8080,
            postreplicate_command    => 'sudo -u tileratorui /usr/local/bin/notify-tilerator',
            disable_replication_cron => $disable_replication_cron,
        }
    } else {
        osm::planet_sync { $db_name:
            ensure                   => present,
            flat_nodes               => true,
            expire_levels            => '15',
            num_threads              => 4,
            use_proxy                => $use_proxy,
            proxy_host               => "webproxy.${::site}.wmnet",
            proxy_port               => 8080,
            period                   => $planet_sync_period,
            day                      => $planet_sync_day,
            hours                    => $planet_sync_hours,
            minute                   => $planet_sync_minute,
            postreplicate_command    => 'sudo -u tileratorui /usr/local/bin/notify-tilerator',
            disable_replication_cron => $disable_replication_cron,
        }
        osm::populate_admin { $db_name:
            ensure             => present,
            disable_admin_cron => $disable_admin_cron,
        }
    }

    class { 'tilerator::regen':
        storage_id => $tilerator_storage_id,
    }

    class { 'osm::prometheus':
        state_path      => '/srv/osmosis/state.txt',
        prometheus_path => '/var/lib/prometheus/node.d/osm_sync_lag.prom',
    }

    # Access to postgres master from postgres replicas
    ferm::service { 'postgres_maps':
        proto  => 'tcp',
        port   => '5432',
        srange => "@resolve((${maps_hosts_ferm}))",
    }

}
