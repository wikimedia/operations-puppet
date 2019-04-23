# == Class: profile::grafana::production
#
# Grafana is a dashboarding webapp for Graphite.
# It powers <https://grafana.wikimedia.org>.
#
class profile::grafana::production {
    include ::profile::grafana

    # On Grafana 5 and later, datasource configurations are stored in Puppet
    # as YAML and pushed to Grafana that way, which reads them at startup.
    # Being on stretch is a proxy for Grafana>=5.
    if os_version('debian >= stretch') {
        file { '/etc/grafana/provisioning/datasources/production-datasources.yaml':
            ensure  => present,
            source  => 'puppet:///modules/profile/grafana/production-datasources.yaml',
            owner   => 'root',
            group   => 'grafana',
            mode    => '0440',
            require => Package['grafana'],
            notify  => Service['grafana-server'],
        }
    }

    grafana::dashboard { 'varnish-http-errors':
        ensure  => absent,
        content => '',
    }

    grafana::dashboard { 'varnish-aggregate-client-status-codes':
        source => 'puppet:///modules/grafana/dashboards/varnish-aggregate-client-status-codes',
    }

    grafana::dashboard { 'swift':
        source => 'puppet:///modules/grafana/dashboards/swift',
    }
}
