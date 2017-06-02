# == Class: kibana
#
# Kibana is a JavaScript web application for visualizing log data and other
# types of time-stamped data. It integrates with ElasticSearch and LogStash.
#
# == Parameters:
# - $settings: hash of settings used to generate the kibanal.yaml configuration
#   file. See https://www.elastic.co/guide/en/kibana/current/settings.html
#   Note: logging.quiet is made to default to true unlike Kibana
#
# == Sample usage:
#
#   class { 'kibana':
#       settings = {
#           kibana.defaultAppId => 'dashboard/default',
#           logging.quiet       => false,
#           elasticsearch_url   => 'http://localhost:9200',
#       }
#   }
#
class kibana ( $settings ) {
    require_package('kibana')

    $default_settings = {
        'logging.quiet' => true,
    }

    file { '/etc/kibana/kibana.yml':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        content => ordered_yaml( merge( $default_settings, $settings ) ),
        mode    => '0444',
        require => Package['kibana'],
    }

    service { 'kibana':
        ensure  => running,
        enable  => true,
        require => [
            Package['kibana'],
            File['/etc/kibana/kibana.yml'],
        ],
    }
}
