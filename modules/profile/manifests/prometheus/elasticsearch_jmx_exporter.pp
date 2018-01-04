class profile::prometheus::elasticsearch_jmx_exporter (
    $prometheus_nodes = hiera('prometheus_nodes'),
) {

    $prometheus_jmx_exporter_port = 9109

    ::profile::prometheus::jmx_exporter { "elasticsearch_${::hostname}":
        hostname         => $::hostname,
        port             => $prometheus_jmx_exporter_port,
        prometheus_nodes => $prometheus_nodes,
        config_file      => '/etc/elasticsearch/prometheus_jmx_exporter.yaml',
        content          => 'puppet:///modules/profile/prometheus/elasticsearch_prometheus_jmx_exporter.yaml',
    }

    # since elasticsearch installs a restrictive security manager, we need to
    # configure some exceptions for the jmx_exporter
    file { '/home/elasticsearch/.java.policy':
        ensure  => present,
        content => 'puppet:///modules/profile/prometheus/elasticsearch_prometheus_jmx_exporter.java.policy',
        mode    => '0644',
        owner   => 'root',
        group   => 'root',
    }

}
