# == Class: statistics::sites::maintenance
#
# This role provisions a webserver with a static sorry page
# meant to be used for Analytics websites under maintenance.
# Example: OS re-image of the server hosting the official
# websites.
#
class statistics::sites::maintenance {

    include ::apache
    include base::firewall

    $docroot  = '/srv/analytics/maintenance'

    git::clone { 'analytics/websites_maintenance':
        ensure    => latest,
        directory => '/srv/analytics/maintenance',
    }

    apache::site { 'datasets.wikimedia.org':
        content => template('statistics/datasets.wikimedia.org_maintenance.erb'),
        require => Git::Clone['analytics/websites_maintenance'],
    }

    apache::site { 'metrics.wikimedia.org':
        content => template('statistics/metrics.wikimedia.org_maintenance.erb'),
        require => Git::Clone['analytics/websites_maintenance'],
    }

    apache::site { 'stats.wikimedia.org':
        content => template('statistics/stats.wikimedia.org_maintenance.erb'),
        require => Git::Clone['analytics/websites_maintenance'],
    }

    ferm::service { 'analytics_http':
        proto => 'tcp',
        port  => '80',
    }
}