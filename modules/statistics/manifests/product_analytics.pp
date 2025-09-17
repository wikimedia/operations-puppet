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
        ensure => absent,
    }

    $jobs_dir = "${dir}/jobs"

    git::clone { 'analytics/wmf-product/jobs':
        ensure    => absent,
        directory => $jobs_dir,
    }

    kerberos::systemd_timer { 'product-analytics-movement-metrics':
        ensure      => absent,
        description => 'Product Analytics monthly Movement Metrics run',
        command     => "${jobs_dir}/movement_metrics/main.sh",
        interval    => '*-*-7 00:00:00',
    }
}
