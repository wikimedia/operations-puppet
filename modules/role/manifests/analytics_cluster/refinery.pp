# == Class role::analytics_cluster::refinery
# Includes configuration and resources needed for deploying
# and using the analytics/refinery repository.
#
class role::analytics_cluster::refinery {
    # Make this class depend on hadoop::client.  Refinery
    # is intended to work with Hadoop, and many of the
    # role classes here use the hdfs user, which is created
    # by the CDH packages.
    Class['role::analytics_cluster::hadoop::client'] -> Class['role::analytics_cluster::refinery']

    # Some refinery python scripts use docopt for CLI parsing.
    if !defined(Package['python-docopt']) {
        package { 'python-docopt':
            ensure => 'installed',
        }
    }
    # refinery python module uses dateutil
    if !defined(Package['python-dateutil']) {
        package { 'python-dateutil':
            ensure => 'installed',
        }
    }

    # analytics/refinery will deployed to this node.
    package { 'analytics/refinery':
        provider => 'trebuchet',
    }

    # analytics/refinery repository is deployed via git-deploy at this path.
    # You must deploy this yourself; puppet will not do it for you.
    $path = '/srv/deployment/analytics/refinery'

    # Put refinery python module in user PYTHONPATH
    file { '/etc/profile.d/refinery.sh':
        content => "export PYTHONPATH=\${PYTHONPATH}:${path}/python"
    }

    # Create directory in /var/log for general purpose Refinery job logging.
    $log_dir = '/var/log/refinery'
    file { $log_dir:
        ensure => 'directory',
        owner  => 'hdfs',
        group  => 'analytics-admins',
        # setgid bit here to make refinery log files writeable
        # by users in the analytics-admins group.
        mode   => '2775',
    }
}