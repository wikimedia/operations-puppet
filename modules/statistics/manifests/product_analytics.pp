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
        ensure => 'directory',
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

    kerberos::systemd_timer { 'product-analytics-movement-metrics':
        ensure            => 'present',
        description       => 'Product Analytics monthly Movement Metrics run',
        command           => "${jobs_dir}/movement_metrics/main.sh",
        interval          => '*-*-7 00:00:00',
        user              => $user,
        logfile_basedir   => $log_dir,
        logfile_name      => 'monthly_movement_metrics.log',
        logfile_owner     => $user,
        logfile_group     => $group,
        send_mail_to      => 'product-analytics@wikimedia.org',
        syslog_force_stop => true,
        syslog_identifier => 'product-analytics-movement-metrics',
        slice             => 'user.slice',
        require           => [
            Class['::statistics::compute'],
            Git::Clone['analytics/wmf-product/jobs']
        ],
    }
}
