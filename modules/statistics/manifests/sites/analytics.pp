# == Class statistics::sites::analytics
# analytics.wikimedia.org
#
# This site will eventually supercede both stats.wikimedia.org
# and datasets.wikimedia.org.  For now it is used to productionize
# various frontend dashboards that have historicaly been running in labs.
#
# Bug: T132407
#
class statistics::sites::analytics {
    require ::statistics::web

    # /srv/analytics.wikimedia.org
    $document_root = "${::statistics::working_path}/analytics.wikimedia.org"
    # Allow statistics-web-users to modify files in this directory.

    git::clone { 'analytics.wikimedia.org':
        ensure    => 'latest',
        directory => $document_root,
        origin    => 'https://gerrit.wikimedia.org/r/analytics/analytics.wikimedia.org',
        owner     => 'root',
        group     => 'statistics-web-users',
        mode      => '0775',
    }

    include ::apache::mod::headers
    apache::site { 'analytics':
        content => template('statistics/analytics.wikimedia.org.erb'),
        require => File[$document_root],
    }
}
