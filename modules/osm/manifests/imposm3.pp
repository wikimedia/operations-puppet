class osm::imposm3 (
    String $proxy_host,
    Stdlib::Port $proxy_port,
    Wmflib::Ensure $ensure            = present,
    String $osm_log_dir               = '/srv/osmosis',
    String $expire_dir                = '/srv/osm_expire',
    Integer $expire_levels            = 15,
    Boolean $disable_replication_cron = false,
) {

    $imposm_diff_dir = '/srv/osm/diff'
    $imposm_cache_dir = '/srv/osm/cache'
    $imposm_mapping_file = '/etc/imposm/imposm_mapping.yml'
    $imposm_config_file = '/etc/imposm/imposm_config.json'

    require_package('imposm3')

    file {
        default:
            ensure => file,
            owner  => 'root',
            group  => 'root',
            mode   => '0755';
        $imposm_diff_dir:
            ensure => directory,
            owner  => 'osmimporter',
            group  => 'osm';
        $imposm_cache_dir:
            ensure => directory,
            owner  => 'osmimporter',
            group  => 'osm';
        $imposm_config_file:
            mode    => '0444',
            content => template('osm/imposm_config.json.erb');
        $imposm_mapping_file:
            mode   => '0444',
            source => 'puppet:///modules/osm/imposm_mapping.yml';
        '/usr/local/bin/imposm-initial-import':
            source => 'puppet:///modules/osm/imposm-initial-import';
        '/usr/local/bin/imposm-rollback-import':
            source => 'puppet:///modules/osm/imposm-rollback-import';
        '/usr/local/bin/imposm-removebackup-import':
            source => 'puppet:///modules/osm/imposm-removebackup-import';
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
}
