# == Define reportupdater::job
#
# Sets up hourly cron jobs to run reportupdater, which generates
# and updates tsv reports for a set of given queries.
#
# This requires that a repository with config and queries for the script
# exists at https://gerrit.wikimedia.org/r/p/analytics/${repository}.git.
#
# == Parameters
#   source_path  - string. [optional] Path where to clone the repository.
#                  Default: $::reportupdater::source_path.
#   repository   - string. [optional] Name of the query repository.
#                  Default: 'analytics/reportupdater-queries'.
#   query_dir    - string. [optional] Path of the directory holding the
#                  queries and the config within the mentioned repository.
#                  Default: $title.
#   log_path     - string. [optional] Path where to write the logs.
#                  Default: '/var/log/reportupdater'.
#   output_path  - string. [optional] Path where to write the reports.
#                  Default: "${source_path}/reportupdater-output".
#
# == Usage
#   reportupdater::job { 'browser': }
#   reportupdater::job { 'mobile':
#       repository  => 'analytics/limn-mobile-data',
#       output_path => "${output_base_path}/mobile/datafiles",
#   }
#
define reportupdater::job(
    $source_path = $::reportupdater::source_path,
    $repository = 'analytics/reportupdater-queries',
    $query_dir  = $title,
    $log_path = '/var/log/reportupdater',
    $output_path = "${source_path}/reportupdater-output",
) {

    Class['::reportupdater'] -> Reportupdater::Job[$title]
    $user = $::reportupdater::user

    # Ensure the query repository is cloned and latest version.
    if !defined(Git::Clone["analytics/${repository}"]) {
        git::clone { "analytics/${repository}":
            ensure    => 'latest',
            directory => "${source_path}/${repository}",
            origin    => "https://gerrit.wikimedia.org/r/p/${repository}.git",
            owner     => $user,
            require   => [User[$user]],
        }
    }

    # Make sure those are writeable by $user.
    file { [$log_path, $output_path]:
        ensure => 'directory',
        owner  => $user,
        group  => wikidev,
        mode   => '0775',
    }

    # Set up the cron job using the specified query directory.
    $query_path = "${source_path}/${repository}/${query_dir}"
    $log_file   = "${log_path}/${repository}_${title}.log"
    cron { "job_${repository}_${title}":
        command => "python update_reports.py ${query_path} ${output_path} >> ${log_file} 2>&1",
        user    => $user,
        minute  => 0,
    }
}
