# == Class profile::analytics::refinery
#
# Includes configuration and resources needed for deploying
# and using the analytics/refinery repository.
#
class profile::analytics::refinery (
    Boolean $deploy_hadoop_config = lookup('profile::analytics::refinery::deploy_hadoop_config', { 'default_value' => true }),
    Boolean $ensure_hdfs_dirs     = lookup('profile::analytics::refinery::ensure_hdfs_dirs', { 'default_value' => false })
) {
    if $deploy_hadoop_config {
        # Make this class depend on hadoop::common configs.  Refinery
        # is intended to work with Hadoop, and many of the
        # role classes here use the hdfs user, which is created
        # by the CDH packages.
        require ::profile::hadoop::common

        require ::profile::analytics::cluster::packages::common
    }

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
        'production' => 'analytics',
        'labs'       => "project-${::wmcs_project}",
    }

    if $deploy_hadoop_config {
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
    }

    # Create HDFS directories for refinery temporary data
    # Those directories are needed to enforce correct ownership of the data
    if $ensure_hdfs_dirs {
        # sudo -u hdfs hdfs dfs -mkdir /wmf/tmp
        # sudo -u hdfs hdfs dfs -chmod 0755 /wmf/tmp
        # sudo -u hdfs hdfs dfs -chown hdfs:hadoop /wmf/tmp
        bigtop::hadoop::directory { '/wmf/tmp':
            owner => 'hdfs',
            group => 'hadoop',
            mode  => '0755',
        }

        # sudo -u hdfs hdfs dfs -mkdir /wmf/tmp/druid
        # sudo -u hdfs hdfs dfs -chmod 0750 /wmf/tmp/druid
        # sudo -u hdfs hdfs dfs -chown analytics:druid /wmf/tmp/druid
        bigtop::hadoop::directory { '/wmf/tmp/druid':
            owner   => 'analytics',
            group   => 'druid',
            mode    => '0750',
            require => Bigtop::Hadoop::Directory['/wmf/tmp'],
        }

        # sudo -u hdfs hdfs dfs -mkdir /wmf/tmp/analytics
        # sudo -u hdfs hdfs dfs -chmod 0750 /wmf/tmp/analytics
        # sudo -u hdfs hdfs dfs -chown analytics:analytics-privatedata-users /wmf/tmp/analytics
        bigtop::hadoop::directory { '/wmf/tmp/analytics':
            owner   => 'analytics',
            group   => 'analytics-privatedata-users',
            mode    => '0750',
            require => Bigtop::Hadoop::Directory['/wmf/tmp'],
        }
    }
}
