# == Class reportupdater
#
# Sets up repositories and rsync for using reportupdater.
# See: https://wikitech.wikimedia.org/wiki/Analytics/Reportupdater
#
# == Parameters
#   $user             - string. User for cloning repositories and
#                       folder permits.
#
#   $base_path        - string. Base path where to put reportupdater's
#                       repository, job query repositories, and data output.
#                       Default: /srv/reportupdater
#
class reportupdater(
    $user,
    $base_path = '/srv/reportupdater',
) {
    $group = 'wikidev'

    # Path at which reportupdater source will be cloned.
    $path = "${base_path}/reportupdater"

    # Path in which all reportupdater output will be stored.
    $output_path = "${base_path}/output"

    # Path in which all reportupdater jobs will log.
    $log_path = "${base_path}/log"

    # Path in which individual reportupdater job repositories
    # will be cloned.
    $job_repositories_path = "${::reportupdater::base_path}/jobs"

    # Ensure these directories exist and are writeable by $user.
    file { [$base_path, $output_path, $log_path, $job_repositories_path]:
        ensure => 'directory',
        owner  => $user,
        group  => $group,
        mode   => '0775',
    }

    # Add logrotate for $log_path/*.log.
    logrotate::conf { 'reportupdater':
        content => template('reportupdater/logrotate.erb'),
        require => File[$log_path],
    }

    # Ensure reportupdater is cloned and latest version.
    git::clone { 'analytics/reportupdater':
        ensure    => 'latest',
        directory => $path,
        origin    => 'https://gerrit.wikimedia.org/r/analytics/reportupdater.git',
        owner     => $user,
        require   => File[$base_path],
    }
}
