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

    $repo_dir = '/srv/analytics/maintenance'
    $docroot  = "${repo_dir}"

    git::clone { 'analytics/websites_maintenance':
        ensure    => latest,
        directory => $repo_dir,
    }

    apache::site { 'datasets.wikimedia.org':
        ensure  => present,
        content => template('statistics/maintenance.erb'),
    }

    apache::site { 'metrics.wikimedia.org':
        ensure  => present,
        content => template('statistics/maintenance.erb'),
    }

    apache::site { 'stats.wikimedia.org':
        ensure  => present,
        content => template('statistics/maintenance.erb'),
    }

    ferm::service { 'analytics_http':
        proto => 'tcp',
        port  => '80',
    }
}