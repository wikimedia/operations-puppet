# == Define reportupdater::job
#
# Sets up hourly systemd timer job to run reportupdater, which generates
# and updates tsv reports for a set of given queries.
#
# This requires that a repository with config and queries for the script
# exists at https://gerrit.wikimedia.org/r/p/analytics/${repository}.git.
#
# == Parameters
#   title        - string. Name of query dir inside of $repository.
#                  a $title directory with reportupdater query config
#                  must exist inside of $repository.
#
#   repository   - string. Name of the query repository in gerrit in the
#                  analytics/ namespace.  All reportupdater job
#                  repositories must be in analytics/
#                  E.g. analytics/reportupdater-queries
#
#   output_dir   - string. [optional] Relative path where to write the reports.
#                  This will be relative to $::reportupdater::base_path/output
#                  Default: $title
#
#   interval     - string. [optional] Systemd time to run the report updater job.
#                  Default: '*-*-* *:00:00' (hourly)
#
# == Usage
#   reportupdater::job { 'browser': }
#
#   reportupdater::job { 'mobile':
#       repository  => 'limn-mobile-data',
#       output_dir  => "mobile/datafiles",
#   }
#
define reportupdater::job(
    $repository = 'reportupdater-queries',
    $output_dir = $title,
    $interval = '*-*-* *:00:00',
    $monitoring_enabled = true,
    $ensure = present,
)
{
    Class['::reportupdater'] -> Reportupdater::Job[$title]

    # Name of the repository in gerrit.
    # All reportupdater job repositories are in the analytics/ namespace.
    $repository_name = "analytics/${repository}"

    # Path at which this reportupdater job repository will be cloned.
    $path            = "${::reportupdater::job_repositories_path}/${repository}"

    # Path of the query configuration directory inside of $repository_name.
    $query_path      = "${path}/${title}"

    # Path at which the job will store its report output.
    $output_path     = "${::reportupdater::output_path}/${output_dir}"

    # Ensure the query repository is cloned and latest version.
    # It is possible that multiple jobs will use the same repository,
    # so wrap this in an if !defined.
    if !defined(Git::Clone[$repository_name]) {
        git::clone { $repository_name:
            ensure    => 'latest',
            directory => $path,
            origin    => "https://gerrit.wikimedia.org/r/${repository_name}.git",
            owner     => $::reportupdater::user,
        }
    }


    systemd::timer::job { "reportupdater-${title}":
        ensure                    => $ensure,
        description               => "Report Updater job for ${title}",
        command                   => "/usr/bin/python ${::reportupdater::path}/update_reports.py -l info ${query_path} ${output_path}",
        interval                  => {
            'start'    => 'OnCalendar',
            'interval' => $interval
        },
        user                      => $::reportupdater::user,
        monitoring_enabled        => $monitoring_enabled,
        monitoring_contact_groups => 'analytics',
        logging_enabled           => true,
        logfile_basedir           => $::reportupdater::log_path,
        logfile_name              => 'syslog.log',
        logfile_owner             => $::reportupdater::user,
        logfile_group             => $::reportupdater::user,
        logfile_perms             => 'all',
        syslog_force_stop         => true,
        syslog_identifier         => "reportupdater-${title}",
    }
}
