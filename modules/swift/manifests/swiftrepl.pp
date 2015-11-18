# instantiate a swift replication job with swiftrepl
#
# === Parameters
# [*source_user*]
#   swift user for source
#
# [*source_api_key*]
#   swift password/api key for source
#
# [*source_auth_url*]
#   authorization URL for source
#
# [*dest_user*]
#   swift user for destination
#
# [*dest_api_key*]
#   swift password/api key for destination
#
# [*dest_auth_url*]
#   authorization URL for destination
#
# [*container_set*]
#   which container set to replicate
#
# [*cron_hour*]
#   hour specification for cron entry
#
# [*cron_minute*]
#   minute specification for cron entry

define swift::swiftrepl (
    $source_user,
    $source_api_key,
    $source_auth_url,
    $dest_user,
    $dest_api_key,
    $dest_auth_url,
    $container_set,
    $cron_hour,
    $cron_minute,
    ) {

    $config_file = "/etc/swiftrepl/${title}.conf"

    group { 'swiftrepl':
        ensure => present,
        system => true,
    }

    user { 'swiftrepl':
        ensure => present,
        gid  => 'swiftrepl',
        home   => '/nonexistent',
        shell  => '/bin/false',
        system => true,
    }

    file { '/etc/swiftrepl':
        ensure => directory,
        mode   => 0500,
        owner  => 'swiftrepl',
        group  => 'swiftrepl',
    }

    file { '/var/log/swiftrepl':
        ensure => directory,
        mode   => 0700,
        owner  => 'swiftrepl',
        group  => 'swiftrepl',
    }

    file { $config_file:
        content => template("${module_name}/swiftrepl.conf.erb"),
        mode    => 0400,
        owner   => 'swiftrepl',
        group   => 'swiftrepl',
    }

    cron { "swiftrepl-${title}":
        ensure  => present,
        command => "/usr/bin/flock --timeout 120 /var/tmp/swiftrepl-${title}.lock /usr/bin/script --flush --return --command '/usr/bin/swiftrepl --config ${config_file} --container-set ${container_set}' /var/log/swiftrepl/${title}-$(date +\\%s).log >/dev/null 2>&1",
        user    => 'swiftrepl',
        hour    => $cron_hour,
        minute  => $cron_minute,
    }

    cron { "swiftrepl-cleanup-${title}":
        ensure  => present,
        command => "/usr/bin/find /var/log/swiftrepl/ -iname '${title}*.log' -type f -mtime +30 -delete",
        user    => 'swiftrepl',
        hour    => '1',
        minute  => '17',
    }

    require_package('swiftrepl')
}
