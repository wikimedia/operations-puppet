# == Class osm::prometheus
# This installs a prometheus Textfile exporter
#
class osm::prometheus(
    $state_path,
    $prometheus_path,
    $ensure = 'present'
) {
    file { '/usr/bin/osm_sync_lag':
        ensure => $ensure,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => "puppet:///modules/${module_name}/osm_sync_lag.sh",
    }

    cron { 'osm_sync_lag':
        ensure  => $ensure,
        command => "/usr/bin/osm_sync_lag ${state_path} >/dev/null 2>&1",
    }
}
