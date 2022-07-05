# SPDX-License-Identifier: Apache-2.0
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

    systemd::timer::job { 'osm_sync_lag':
        ensure          => $ensure,
        description     => 'Regular jobs for running osm_sync_lag',
        user            => 'root',
        command         => "/usr/bin/osm_sync_lag ${state_path} ${prometheus_path}",
        logging_enabled => false,
        interval        => {'start' => 'OnCalendar', 'interval' => 'minutely'}
    }
}
