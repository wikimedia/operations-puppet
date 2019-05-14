define osm::cleartables_sync (
    Boolean $use_proxy,
    String $proxy_host,
    Stdlib::Port $proxy_port,
    Wmflib::Ensure $ensure            = 'present',
    String $postreplicate_command     = undef,
    Boolean $disable_replication_cron = false,
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

    $ensure_cron = $disable_replication_cron ? {
        true    => absent,
        default => $ensure,
    }

    $base_cron_command = "/usr/local/bin/process-osm-data planet-update >> ${log_dir}/planet-update.log 2>&1"
    $planet_update_cron_command = $postreplicate_command ? {
        undef   => $base_cron_command,
        default => "${base_cron_command} ; ${postreplicate_command} >> ${log_dir}/planet-update.log 2>&1"
    }

    $java_proxy = "\"-Dhttp.proxyHost=${proxy_host} -Dhttp.proxyPort=${proxy_port} -Dhttps.proxyHost=${proxy_host} -Dhttps.proxyPort=${proxy_port}\""

    $environment = $use_proxy ? {
        false   => [],
        default => ["https_proxy=https://${proxy_host}:${proxy_port}", "JAVACMD_OPTIONS=${java_proxy}"],
    }

    cron {
        default:
            ensure      => $ensure_cron,
            user        => 'osmupdater',
            environment => $environment;
        "planet_sync-${name}": # TODO: cleanup after this cron is renamed
            ensure => absent;
        "planet_update-${name}":
            command => $planet_update_cron_command,
            hour    => [0, 6, 12, 18],
            minute  => 02;
        "database_update-${name}":
            command => "/usr/local/bin/process-osm-data database-update >> ${log_dir}/database-update.log 2>&1",
            minute  => '*/5';
        "static_update-${name}":
            command => "/usr/local/bin/process-osm-data static-update >> ${log_dir}/static-update.log 2>&1",
            minute  => '*';
    }

}
