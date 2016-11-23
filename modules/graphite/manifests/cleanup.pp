# == Class: graphite::cleanup
#
# Cleanup utilities for Graphite metric maintenance.
#
class graphite::cleanup(
    $storage_dir,
) {
    file { '/usr/local/bin/cleanup-old-files':
        ensure => present,
        source => 'puppet:///modules/graphite/cleanup-old-files',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    cron { 'graphite-cleanup-labs-instances':
        command => "FORCE=y /usr/local/bin/cleanup-old-files ${storage_dir}/instances | logger -t graphite-cleanup-labs-instances",
        user    => '_graphite',
        hour    => 0,
        minute  => fqdn_rand(60),
    }
}
