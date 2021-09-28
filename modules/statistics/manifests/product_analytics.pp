# = Class: statistics::product_analytics
# Maintainer: Mikhail Popov (bearloga)
# Team: https://www.mediawiki.org/wiki/Product_Analytics
class statistics::product_analytics {
    Class['::statistics'] -> Class['::statistics::product_analytics']

    $working_path = $::statistics::working_path
    # Homedir for everything Wikimedia Product Analytics related
    $dir = "${working_path}/product_analytics"
    # Path in which logs will reside
    $log_dir = "${dir}/logs"

    $user = 'analytics-product'
    $group ='analytics-privatedata-users'

    $directories = [
        $dir,
        $log_dir
    ]

    file { $directories:
        ensure => 'present',
        owner  => $user,
        group  => $group,
        mode   => '0775',
    }

    $jobs_dir = "${dir}/jobs"

    git::clone { 'analytics/wmf-product/jobs':
        ensure             => 'latest',
        branch             => 'master',
        recurse_submodules => true,
        directory          => $jobs_dir,
        owner              => $user,
        group              => $group,
        require            => File[$dir],
    }

    # Initially, since the jobs/movement_metrics dir only has a test notebook
    # we want to verify that the scheduled execution works as expected. After
    # verification we can switch the interval from the initial configuration
    # of Monday and Wednesday to monthly -- for example, the 9th of every month
    # to make sure that a new MediaWiki History snapshot has been generated
    # (since those take up to 8 days).
    kerberos::systemd_timer { 'product-analytics-movement-metrics':
        ensure            => 'present',
        description       => 'Product Analytics monthly Movement Metrics run',
        command           => "${jobs_dir}/movement_metrics/main.sh",
        interval          => 'Mon,Wed *-*-* 00:00:00', # execute every Mon & Wed
        user              => $user,
        logfile_basedir   => $log_dir,
        logfile_name      => 'monthly_movement_metrics.log',
        logfile_owner     => $user,
        logfile_group     => $group,
        syslog_force_stop => true,
        slice             => 'user.slice',
        require           => [
            Class['::statistics::compute'],
            Git::Clone['analytics/wmf-product/jobs']
        ],
    }
}
