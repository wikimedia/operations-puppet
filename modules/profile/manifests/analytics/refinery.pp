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

    # Clone mediawiki/event-schemas so refinery can use them.
    class { '::eventschemas': }

    # Include geoip for geolocating
    class { '::geoip': }

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

    # The analytics/refinery repo will deployed to this node via Scap3.
    # The analytics user/groups are deployed/managed by Scap.
    # The analytics_deploy SSH keypair files are stored in the private repo,
    # and since manage_user is true the analytics_deploy public ssh key
    # will be added to the 'analytics' user's ssh config. The rationale is to
    # have a single 'analytics' multi-purpose user that owns refinery files
    # deployed via scap and could possibly do other things (not yet defined).
    scap::target { 'analytics/refinery':
        deploy_user => 'analytics',
        key_name    => 'analytics_deploy',
        manage_user => true,
    }

    # analytics/refinery repository is deployed via git-deploy at this path.
    # You must deploy this yourself; puppet will not do it for you.
    $path = '/srv/deployment/analytics/refinery'

    # Put refinery python module in user PYTHONPATH
    file { '/etc/profile.d/refinery.sh':
        content => "export PYTHONPATH=\${PYTHONPATH}:${path}/python",
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
        # by users in the $$log_dir_group group.
        mode   => '2775',
    }

    logrotate::conf { 'refinery':
        source  => 'puppet:///modules/profile/analytics/refinery-logrotate.conf',
        require => File[$log_dir],
    }
}
