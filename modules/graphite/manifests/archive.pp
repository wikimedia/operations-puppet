# == Class: graphite::archive
#
# Provide a local listener to accept plaintext metrics and archive them to
# disk. The metrics archive can be used to recover from data loss or backfill
# the metrics elsewhere for example.

class graphite::archive(
    $storage_dir = '/var/lib/carbon',
) {
    require_package('cronolog', 'netcat-traditional', 'logrotate')

    $carbon_archive_path = '/usr/bin/carbon-archive'

    file { '/etc/init/carbon/archive.conf':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('graphite/archive.upstart.conf.erb'),
        notify  => Service['carbon/archive'],
    }

    file { $carbon_archive_path:
        source => 'puppet:///modules/graphite/carbon-archive',
        mode   => '0555',
        before => Service['carbon/archive'],
    }

    file { '/etc/logrotate.d/carbon-archive':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('graphite/archive.logrotate.conf.erb'),
    }

    service { 'carbon/archive':
        ensure   => 'running',
        provider => 'upstart',
    }
}
