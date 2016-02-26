# == Define reportupdater::job
#
# Sets up hourly cron jobs to run a script which generates and updates
# tsv datafiles for a set of given queries.
#
# This requires that a repository with config and queries for the script
# exists at https://gerrit.wikimedia.org/r/p/analytics/${repository}.git.
#
# == Parameters
#   repository   - string. [optional] Name of the repository holding the
#                  queries and the config. Default: "limn-${title}-data".
#   query_dir    - string. [optional] Path of the directory holding the
#                  queries and the config within the mentioned repository.
#                  Default: "${title}".
#
# == Usage
#   reportupdater::job { 'mobile': }
#   reportupdater::job { 'browser':
#       repository => 'reportupdater-queries',
#   }
#
define reportupdater::job(
    $repository = "limn-${title}-data",
    $query_dir  = $title,
) {
    Class['::reportupdater'] -> Reportupdater::Job[$title]

    $user    = $::reportupdater::user
    $command = $::reportupdater::command

    # A repo at analytics/${repository}.git had better exist!
    $git_remote = "https://gerrit.wikimedia.org/r/p/analytics/${repository}.git"

    # Directory at which to clone $git_remote.
    $source_path = "${::reportupdater::working_path}/${repository}"

    # Config directory for this report generating job.
    $query_path = "${$source_path}/${query_dir}"

    # Log file for the generate/reportupdater cron job.
    $log_file = "${::reportupdater::log_path}/${repository}_${title}.log"

    if !defined(Git::Clone["analytics/${repository}"]) {
        git::clone { "analytics/${repository}":
            ensure    => 'latest',
            directory => $source_path,
            origin    => $git_remote,
            owner     => $user,
            require   => [User[$user]],
        }
    }

    cron { "generate_${repository}_${title}":
        command => "${command} ${query_path} >> ${log_file} 2>&1",
        user    => $user,
        minute  => 0,
    }
}
