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
    $default_app_id = 'dashboard/default',
    $kibana_package = 'kibana'
) {
    package { 'kibana':
        ensure => 'present',
        name   => $kibana_package,
    }

    # ugly hack to solve https://phabricator.wikimedia.org/T192279 / https://github.com/elastic/kibana/issues/12915
    file { '/usr/share/kibana/optimize/bundles/stateSessionStorageRedirect.style.css':
        ensure => present,
        owner  => 'kibana',
        group  => 'kibana',
        mode   => '0664',
    }

    file { '/etc/kibana/kibana.yml':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        content => ordered_yaml({
            'kibana.defaultAppId'    => $default_app_id,
            'logging.quiet'          => true,
            'server.maxPayloadBytes' => 4194304, # 4MB (yes, this is a crazy limit, we need to reduce the number of fields)
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

    class { '::kibana::phatality': }
}
