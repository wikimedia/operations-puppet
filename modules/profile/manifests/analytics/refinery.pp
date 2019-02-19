# == Class profile::analytics::refinery
#
# Includes configuration and resources needed for deploying
# and using the analytics/refinery repository.
#
class profile::analytics::refinery {
    # Make this class depend on hadoop::common configs.  Refinery
    # is intended to work with Hadoop, and many of the
    # role classes here use the hdfs user, which is created
    # by the CDH packages.
    require ::profile::hadoop::common

    require ::profile::analytics::cluster::packages::hadoop

    require ::profile::analytics::refinery::repository

    # Needed to make the analytics-mysql tool work
    package { 'python3-dnspython':
        ensure => installed,
    }

    # Wrapper script to ease the use of the analytics-mysql
    # tool (shipped with Refinery)
    file { '/usr/local/bin/analytics-mysql':
        source => 'puppet:///modules/profile/analytics/refinery/analytics-mysql',
        mode   => '0555'
    }

    # Required by a lot of profiles dependent on this one
    # to find the correct path for scripts etc..
    $path = $::profile::analytics::refinery::repository::path

    # Create directory in /etc for general purpose refinery config.
    $config_dir = '/etc/refinery'
    file { $config_dir:
        ensure => 'directory'
    }

    # Create directory in /var/log for general purpose Refinery job logging.
    $log_dir = '/var/log/refinery'
    $log_dir_group = $::realm ? {
        'production' => 'analytics-admins',
        'labs'       => "project-${::labsproject}",
    }
    file { $log_dir:
        ensure => 'directory',
        owner  => 'hdfs',
        group  => $log_dir_group,
        # setgid bit here to make refinery log files writeable
        # by users in the $log_dir_group group.
        mode   => '2775',
    }

    logrotate::conf { 'refinery':
        source  => 'puppet:///modules/profile/analytics/refinery-logrotate.conf',
        require => File[$log_dir],
    }

    # Clone mediawiki/event-schemas so refinery can use them.
    class { '::eventschemas': }
}
