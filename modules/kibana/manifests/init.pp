# == Class: kibana
#
# Kibana is a JavaScript web application for visualizing log data and other
# types of time-stamped data. It integrates with ElasticSearch and LogStash.
#
# == Parameters:
# - $default_route: Default landing page. You can specify files, scripts or
#     saved dashboards here. Default: '/dashboard/file/default.json'.
#
# == Sample usage:
#
#   class { 'kibana':
#       default_route => '/dashboard/elasticsearch/default',
#   }
#
class kibana (
    $default_route = '/dashboard/file/default.json'
) {
    package { 'kibana':
        provider => 'trebuchet',
    }

    file { '/etc/kibana':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { '/etc/kibana/config.js':
        ensure  => present,
        content => template('kibana/config.js'),
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
    }
}
