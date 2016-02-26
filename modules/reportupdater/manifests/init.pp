# == Class reportupdater
#
# Sets up base directories and repositories for using reportupdater.
# See: https://wikitech.wikimedia.org/wiki/Analytics/Reportupdater
#
# == Parameters
#   $user           - string. User to clone the repositories and attribute
#                     the permits to.
#   $working_path   - string. Base path where to put the necessary repositories.
#   $log_path       - string. [optional] Path where to write the generator logs.
#                     Default: '/var/log/reportupdater'.
#   $output_path    - string. [optional] Path to output the generated reports.
#                     Default: "${working_path}/reportupdater-output".
#   $rsync_to       - string. [optional] If defined, all what is in the output
#                     path will be rsync'd to $rsync_to.
#   $generator      - string. The generator that will manage the reports.
#                     Either 'generate' or 'reportupdater'.
#
class reportupdater(
    $user,
    $working_path,
    $log_path          = '/var/log/reportupdater',
    $output_path       = "${working_path}/reportupdater-output",
    $rsync_to          = undef,
    $generator         = 'reportupdater',
) {

    # There are 2 generator scripts for now. Each one has its own:
    #   $git_remote   - Repository where to pull the generator from.
    #   $source_path  - Directory where to clone the repository to.
    #   $command      - Command to execute the generator.
    #
    case $generator {
        generate: {
            $git_remote  = 'https://gerrit.wikimedia.org/r/p/analytics/limn-mobile-data.git'
            $source_path = "${working_path}/limn-mobile-data"
            $command     = "python ${source_path}/generate.py"
        }
        reportupdater: {
            $git_remote  = 'https://gerrit.wikimedia.org/r/p/analytics/reportupdater.git'
            $source_path = "${working_path}/reportupdater"
            $command     = "python ${source_path}/update_reports.py"
        }
    }

    # Ensure the generator is cloned and latest version.
    if !defined(Git::Clone['analytics/reportupdater']) {
        git::clone { 'analytics/reportupdater':
            ensure    => 'latest',
            directory => $source_path,
            origin    => $git_remote,
            owner     => $user,
            require   => [User[$user]],
        }
    }

    # Make sure these are writeable by $user.
    file { [$log_path, $output_path]:
        ensure => 'directory',
        owner  => $user,
        group  => wikidev,
        mode   => '0775',
    }

    # If specified, rsync anything generated in $public_dir to $rsync_to.
    if $rsync_to != undef {
        cron { 'rsync_reportupdater_output':
            command => "/usr/bin/rsync -rt ${output_path}/* ${rsync_to}",
            user    => $user,
            minute  => 15,
        }
    }
}
