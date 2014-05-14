# == Class: role::grafana
#
# Grafana is an open-source, feature-rich metrics dashboard and graph
# editor for Graphite & InfluxDB. It powers <https://grafana.wikimedia.org>.
#
class role::grafana {
    case $::realm {
        'labs': { $graphiteUrl = 'graphite.wmflabs.org' }
        default: { $graphiteUrl = 'graphite.wikimedia.org' }
    }

    class { '::grafana':
        config => { graphiteUrl => $graphiteUrl, },
    }

    include ::apache
    include ::apache::mod::uwsgi

    file { '/etc/apache2/sites-available/grafana':
        content => template('apache/sites/grafana.wikimedia.org.erb'),
        require => Package['httpd'],
    }

    file { '/etc/apache2/sites-enabled/grafana':
        ensure => link,
        target => '/etc/apache2/sites-available/grafana',
        notify => Service['httpd'],
    }

    monitor_service { 'grafana':
        description   => 'grafana.wikimedia.org',
        check_command => 'check_http_url!grafana.wikimedia.org!/',
    }
}
