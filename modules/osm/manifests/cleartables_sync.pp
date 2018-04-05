define osm::cleartables_sync (
    String $pg_password,
    Wmflib::Ensure $ensure        = 'present',
    String $hour                  = '*',
    String $minute                = '*/30',
    String $postreplicate_command = undef,
    String $proxy_host            = 'webproxy.eqiad.wmnet',
    Wmflib::IpPort $proxy_port    = 8080,
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

    logrotate::rule { 'cleartables-sync':
        ensure     => present,
        file_glob  => "${log_dir}/planet-update.log",
        frequency  => 'daily',
        max_age    => 30,
        rotate     => 7,
        date_ext   => true,
        compress   => true,
        missing_ok => true,
        no_create  => true,
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
            "https_proxy=https://${proxy_host}:${proxy_port}",
            "JAVACMD_OPTIONS=\"-Dhttp.proxyHost=${proxy_host} -Dhttp.proxyPort=${proxy_port} -Dhttps.proxyHost=${proxy_host} -Dhttps.proxyPort=${proxy_port}"
        ],
    }

}
