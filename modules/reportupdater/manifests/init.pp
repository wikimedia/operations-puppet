# == Class reportupdater
#
# Sets up repositories and rsync for using reportupdater.
# See: https://wikitech.wikimedia.org/wiki/Analytics/Reportupdater
#
# == Parameters
#   $user             - string. User for cloning repositories and
#                       folder permits.
#
#   $base_path        - string. Base path where to put all reportupdater's
#                       necessary files: source code, output, logs and jobs.
#                       Default: /srv/reportupdater
#
#   $log_path         - string. Path where to put reportupdater's logs.
#                       Default: ${base_path}/log
#
class reportupdater (
    $user,
    $base_path = '/srv/reportupdater',
    $log_path  = undef,
) {
    $group = 'wikidev'

    # Path at which reportupdater source will be cloned.
    $source_path = "${base_path}/reportupdater"

    # Path in which all reportupdater output will be stored.
    $output_path = "${base_path}/output"

    # Path in which all reportupdater jobs will log.
    if $log_path == undef {
        $log_path = "${base_path}/log"
    }

    # Path in which individual reportupdater job repositories
    # will be cloned.
    $jobs_path = "${base_path}/jobs"

    # Ensure these directories exist and are writeable by $user.
    file { [$base_path, $output_path, $log_path, $jobs_path]:
        ensure => absent,
        owner  => $user,
        group  => $group,
        mode   => '0775',
    }

    # Add logrotate for $log_path/*.log.
    logrotate::conf { 'reportupdater':
        ensure  => absent,
        content => template('reportupdater/logrotate.erb'),
        require => File[$log_path],
    }

    package { 'python3-pid':
        ensure => absent,
    }

    # Ensure reportupdater is cloned and latest version.
    git::clone { 'analytics/reportupdater':
        ensure    => absent,
        directory => $source_path,
        origin    => 'https://gerrit.wikimedia.org/r/analytics/reportupdater.git',
        owner     => $user,
        require   => [File[$base_path], Package['python3-pid']],
    }
}
