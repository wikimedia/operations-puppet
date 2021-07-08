class profile::wmcs::metricsinfra::haproxy (
    Array[Stdlib::Fqdn] $prometheus_hosts = lookup('profile::wmcs::metricsinfra::prometheus_hosts'),
    Array[Stdlib::Fqdn] $prometheus_alertmanager_hosts = lookup('profile::wmcs::metricsinfra::prometheus_alertmanager_hosts'),
) {
    class { 'haproxy::cloud::base': }

    file { '/etc/haproxy/conf.d/prometheus.cfg':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('profile/wmcs/metricsinfra/haproxy/prometheus.cfg.erb'),
        notify  => Service['haproxy'],
    }

    class { '::prometheus::haproxy_exporter':
        listen_port => 9901,
    }
}
