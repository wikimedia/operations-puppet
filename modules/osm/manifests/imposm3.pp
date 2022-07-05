# SPDX-License-Identifier: Apache-2.0
class osm::imposm3 (
    String $proxy_host,
    Stdlib::Port $proxy_port,
    String $swift_key_id,
    String $swift_password,
    String $tegola_swift_container,
    Wmflib::Ensure $ensure            = present,
    String $upstream_url_path         = 'planet.openstreetmap.org',
    String $osm_log_dir               = '/srv/osm/log',
    String $expire_dir                = '/srv/osm_expire',
    Integer $expire_levels            = 15,
    Boolean $disable_replication_cron = false,
    String $eventgate_endpoint        = 'https://eventgate-main.discovery.wmnet:4492/v1/events',
) {

    $imposm_dir = '/srv/osm'
    $imposm_diff_dir = '/srv/osm/diff'
    $imposm_cache_dir = '/srv/osm/cache'
    $imposm_mapping_file = '/etc/imposm/imposm_mapping.yml'
    $imposm_config_file = '/etc/imposm/imposm_config.json'
    $min_expire_level = 0

    ensure_packages('imposm3')

    file {
        default:
            ensure => file,
            owner  => 'root',
            group  => 'root',
            mode   => '0755';
        '/srv/osm':
            ensure => directory,
            owner  => 'osmupdater',
            group  => 'osm';
        '/etc/imposm':
            ensure => directory,
            owner  => 'osmupdater',
            group  => 'osm';
        $imposm_diff_dir:
            ensure => directory,
            owner  => 'osmupdater',
            group  => 'osm';
        $imposm_cache_dir:
            ensure => directory,
            owner  => 'osmupdater',
            group  => 'osm';
        $imposm_config_file:
            mode    => '0444',
            content => template('osm/imposm_config.json.erb');
        $imposm_mapping_file:
            mode   => '0444',
            source => 'puppet:///modules/osm/imposm_mapping.yml';
        '/usr/local/bin/kafka-consume-messages':
            source => 'puppet:///modules/osm/kafka-scripts/consume-messages.py';
        '/usr/local/bin/kafka-commit-last-message':
            source => 'puppet:///modules/osm/kafka-scripts/commit-last-message.py';
        '/usr/local/bin/create_layers_functions':
            source => 'puppet:///modules/osm/create_layers_functions';
        '/usr/local/bin/imposm-initial-import':
            source => 'puppet:///modules/osm/imposm-initial-import';
        '/usr/local/bin/imposm-rollback-import':
            source => 'puppet:///modules/osm/imposm-rollback-import';
        '/usr/local/bin/imposm-removebackup-import':
            source => 'puppet:///modules/osm/imposm-removebackup-import';
        '/usr/local/bin/send-tile-expiration-events':
            source => 'puppet:///modules/osm/send-tile-expiration-events.sh';
        '/etc/imposm/event-template.json':
            source => 'puppet:///modules/osm/event-template.json';
    }

    $ensure_replication = $disable_replication_cron ? {
        true    => absent,
        default => $ensure,
    }

    # service init script and activation
    systemd::service { 'imposm':
        ensure    => $ensure_replication,
        content   => systemd_template('imposm'),
        restart   => true,
        subscribe => File[$imposm_config_file],
        require   => [
            Package['imposm3'],
            File[$imposm_mapping_file],
            File[$imposm_config_file],
        ],
    }

    systemd::timer::job { 'send_tile_invalidations':
        ensure      => present,
        description => 'Send events to EventPlatform to invalidate stale tiles',
        interval    => {
            'start'    => 'OnCalendar',
            'interval' => '*-*-* 13:00:00',
        },
        environment => {
            'ST_AUTH'         => 'https://thanos-swift.discovery.wmnet/auth/v1.0',
            'ST_USER'         => $swift_key_id,
            'ST_KEY'          => $swift_password,
            'CACHE_CONTAINER' => $tegola_swift_container
        },
        user        => 'osmupdater',
        command     => "/usr/local/bin/send-tile-expiration-events ${imposm_dir} ${expire_dir} ${min_expire_level} ${expire_levels} ${eventgate_endpoint}"
    }
}
