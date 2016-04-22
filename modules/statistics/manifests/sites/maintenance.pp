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

    $docroot  = '/srv/maintenance'

    file { '/srv/analytics':
        ensure => 'directory',
        purge  => true,
    }

    file { '/srv/analytics/maintenance':
        ensure => 'directory',
        purge  => true,
    }

    git::clone { 'analytics/websites_maintenance':
        ensure    => latest,
        directory => '/srv/analytics/maintenance',
    }

    # A single vhost containing multiple ServerAliases will be created
    # for datasets.w.o, metrics.w.o, stats.w.o
    apache::site { 'statistics_maintenance':
        content => template('statistics/analytics_maintenance_vhost.erb'),
    }

    ferm::service { 'analytics_http':
        proto => 'tcp',
        port  => '80',
    }
}