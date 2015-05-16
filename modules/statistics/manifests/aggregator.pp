# == Class statistics::aggregator
# Handles aggregation of pagecounts-all-sites projectcounts files
# TODO: Should this be in its own module?
#
class statistics::aggregator {
    Class['::statistics'] -> Class['::statistics::aggregator']

    # This class uses the cdh::hadoop::mount in order to get
    # data files out of HDFS.
    Class['cdh::hadoop::mount'] -> Class['::statistics::aggregator']

    $working_path     = "${::statistics::working_path}/aggregator"

    $script_path      = "${working_path}/scripts"
    $data_repo_path   = "${working_path}/data"
    $data_path        = "${data_repo_path}/projectcounts"
    $log_path         = "${working_path}/log"
    # This should not be hardcoded.  Instead, one should be able to use
    # $::cdh::hadoop::mount::mount_point to reference the user supplied
    # parameter when the cdh::hadoop::mount class is evaluated.
    # I am not sure why this is not working.
    $hdfs_mount_point = '/mnt/hdfs'
    $hdfs_source_path = "${hdfs_mount_point}/wmf/data/archive/pagecounts-all-sites"
    $user             = $::statistics::user::username
    $group            = $::statistics::user::username

    file { $working_path:
        ensure => 'directory',
        owner  => $user,
        group  => $group,
        mode   => '0755'
    }

    git::clone { 'aggregator_code':
        ensure    => 'latest',
        directory => $script_path,
        origin    => 'https://gerrit.wikimedia.org/r/p/analytics/aggregator.git',
        owner     => $user,
        group     => $group,
        mode      => '0755',
        require   => File[$working_path],
    }

    git::clone { 'aggregator_data':
        ensure    => 'latest',
        directory => $data_repo_path,
        origin    => 'https://gerrit.wikimedia.org/r/p/analytics/aggregator/data.git',
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
    cron { 'aggregator projectcounts aggregate':
        command => "${script_path}/bin/aggregate_projectcounts --source ${hdfs_source_path} --target ${data_path} --first-date=`date --date='-8 day' +\\%Y-\\%m-\\%d` --last-date=`date --date='-1 day' +\\%Y-\\%m-\\%d` --push-target --log ${log_path}/`date +\\%Y-\\%m-\\%d--\\%H-\\%M-\\%S`.log",
        user    => $user,
        hour    => '13',
        minute  => '0',
        require => [
            Git::Clone['aggregator_code'],
            Git::Clone['aggregator_data'],
            File[$log_path],
        ],
    }

    # Cron for basing monitoring of the aggregated data
    cron { 'aggregator projectcounts monitor':
        command => "${script_path}/bin/check_validity_aggregated_projectcounts --data ${data_path}",
        user    => $user,
        hour    => '13',
        minute  => '45',
        require => Cron['aggregator projectcounts aggregate'],
    }
}
