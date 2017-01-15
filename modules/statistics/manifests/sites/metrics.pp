# == Class statistics::sites::metrics
# metrics.wikimedia.org and metrics-api.wikimedia.org
# They should just redirect to Wikimetrics
#
class statistics::sites::metrics {
    require ::statistics::web

    include ::apache::mod::alias

    # Set up the VirtualHost
    apache::site { 'metrics.wikimedia.org':
        content => template('statistics/metrics.wikimedia.org.erb'),
    }

    # make access and error log for metrics-api readable by wikidev group
    file { ['/var/log/apache2/access.metrics.log', '/var/log/apache2/error.metrics.log']:
        group   => 'wikidev',
    }
}
