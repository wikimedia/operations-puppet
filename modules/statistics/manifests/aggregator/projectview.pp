# == Class statistics::aggregator::projectview
# Handles aggregation of projectview_hourly files
#
# WARNING - Files aggregated by this instance are using the
# new pageview definition. The legacy ones are no longer 
# being calculated
#
class statistics::aggregator::projectview {
    require statistics::aggregator

    # This class uses the cdh::hadoop::mount in order to get
    # data files out of HDFS.
    Class['cdh::hadoop::mount'] -> Class['::statistics::aggregator::projectview']

    $script_path      = $::statistics::aggregator::script_path
    $working_path     = "${::statistics::aggregator::working_path}/projectview"
    $data_repo_path   = "${working_path}/data"
    $data_path        = "${data_repo_path}/projectview"
    $log_path         = "${working_path}/log"
    # This should not be hardcoded.  Instead, one should be able to use
    # $::cdh::hadoop::mount::mount_point to reference the user supplied
    # parameter when the cdh::hadoop::mount class is evaluated.
    # I am not sure why this is not working.
    $hdfs_mount_point = '/mnt/hdfs'
    $hdfs_source_path = "${hdfs_mount_point}/wmf/data/archive/projectview/legacy/hourly"
    $user             = $::statistics::user::username
    $group            = $::statistics::user::username

    file { $working_path:
        ensure => 'directory',
        owner  => $user,
        group  => $group,
        mode   => '0755'
    }

    git::clone { 'aggregator_projectview_data':
        ensure    => 'latest',
        directory => $data_repo_path,
        origin    => 'https://gerrit.wikimedia.org/r/p/analytics/aggregator/projectview/data.git',
        owner     => $user,
        group     => $group,
        mode      => '0755',
        require   => File[$working_path],
    }

    file { $log_path:
        ensure  => 'directory',
        owner   => $user,
        group   => $group,
        mode    => '0755',
        require => File[$working_path],

    }

    # Cron for doing the basic aggregation step itself
    # Note that the --all-projects flag is set to compute aggregates across all projects.
    # Note that the --output-projectviews flag is set to use input files that look like projectviews-*
    cron { 'aggregator projectview aggregate':
        command => "log_file=\"${log_path}/`date +\\%Y-\\%m-\\%d--\\%H-\\%M-\\%S`.log\" && ${script_path}/bin/aggregate_projectcounts --source ${hdfs_source_path} --target ${data_path} --first-date=`date --date='-8 day' +\\%Y-\\%m-\\%d` --last-date=`date --date='-1 day' +\\%Y-\\%m-\\%d` --all-projects --output-projectviews --push-target --log \${log_file} 2>> \${log_file}",
        user    => $user,
        hour    => '13',
        minute  => '0',
        require => [
            Git::Clone['aggregator_projectview_data'],
            File[$log_path],
        ],
    }

    # Cron for basing monitoring of the aggregated data
    cron { 'aggregator projectview monitor':
        command => "${script_path}/bin/check_validity_aggregated_projectcounts --data ${data_path}",
        user    => $user,
        hour    => '13',
        minute  => '45',
        require => Cron['aggregator projectview aggregate'],
    }
}
