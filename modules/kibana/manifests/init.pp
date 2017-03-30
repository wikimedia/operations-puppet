# == Class: kibana
#
# Kibana is a JavaScript web application for visualizing log data and other
# types of time-stamped data. It integrates with ElasticSearch and LogStash.
#
# == Parameters:
# - $default_app_id: Default landing page. You can specify files, scripts or
#     saved dashboards here. Default: '/dashboard/file/default.json'.
#
# == Sample usage:
#
#   class { 'kibana':
#       default_app_id => 'dashboard/default',
#   }
#
class kibana (
    $default_app_id = 'dashboard/default'
) {
    require_package('kibana')

    file { '/etc/kibana/kibana.yml':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        content => ordered_yaml({
            'kibana.defaultAppId' => $default_app_id,
            'logging.quiet'       => true,
        }),
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

    # kibana 4.x deployment. With 5.x things are
    # installed normally and not in /opt
    file { '/opt/kibana':
        ensure => absent
    }
}
