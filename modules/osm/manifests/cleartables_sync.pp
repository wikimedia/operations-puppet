define osm::cleartables_sync (
    $pg_password,
    $ensure = 'present',
    $hour   = '*',
    $minute = '*/30',
    $postreplicate_command = undef,
    $proxy='webproxy.eqiad.wmnet:8080',
) {

    $log_dir = '/var/log/osm_replication/'

    include ::osm::meddo
    include ::osm::users

    file { '/usr/local/bin/process-osm-data':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/osm/process-osm-data.sh',
    }

    file { [ $log_dir, '/srv/osm_replication' ]:
        ensure => directory,
        owner  => 'osmupdater',
        group  => 'osmupdater',
        mode   => '0755',
    }

    logrotate::conf {'cleartables-sync':
        ensure  => present,
        content => template('osm/cleartables-sync-logrotate.conf.erb')
    }

    $base_cron_command = "/usr/local/bin/process-osm-data planet-update >> ${log_dir}/planet-update.log 2>&1"
    $cron_command = $postreplicate_command ? {
        undef   => $base_cron_command,
        default => "${base_cron_command} ; ${postreplicate_command} >> ${log_dir}/planet-update.log 2>&1"
    }

    cron { "planet_sync-${name}":
        ensure      => $ensure,
        command     => $cron_command,
        user        => 'osmupdater',
        hour        => $hour,
        minute      => $minute,
        environment => [
            "PGPASSWORD=${pg_password}",
            "https_proxy=https://${proxy}",
        ],
    }

}