# == Class statistics::sites::metrics
# metrics.wikimedia.org and metrics-api.wikimedia.org
# They should just redirect to Wikimetrics
#
class statistics::sites::metrics {
    Class['::statistics::web'] -> Class['::statistics::sites::datasets']
    include ::apache::mod::alias

    $site_name       = 'metrics.wikimedia.org'
    $redirect_target = 'https://metrics.wmflabs.org/'

    # Set up the VirtualHost
    apache::site { $site_name:
        content => template("modules/statistics/metrics.wikimedia.org.erb"),
    }

    # make access and error log for metrics-api readable by wikidev group
    file { ['/var/log/apache2/access.metrics.log', '/var/log/apache2/error.metrics.log']:
        group   => 'wikidev',
    }
}
