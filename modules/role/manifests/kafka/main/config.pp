# == Class role::kafka::main::config
# Kafka config class for a main Kafka cluster.
# This class only contains variable definitions,
# so it is safe to include anywhere in order to
# reference them.
#
class role::kafka::main::config {
    # Choose cluster name from hiera, or default appropriately
    # in labs or production.
    $cluster_name = hiera('kafka_cluster_name', $::realm ? {
        'labs'       => "main-${::labsproject}",
        'production' => "main-${::site}",
    })


    $default_clusters = {
        $cluster_name => {
            'brokers' => {
                $::fqdn => {
                    'id' => '1',
                },
            }
        }
    }
    # Get all kafka cluster configs from hiera,
    # or default to only single node cluster for $cluster_name.
    $all_clusters   = hiera('kafka_clusters', $default_clusters)

    # Config hash suitable for passing to kafka::server's broker param
    $brokers_config  = $clusters[$cluster_name]['brokers']
    # Array of broker hostnames in thie Kafka cluster
    $brokers_array   = keys($brokers_config)
    # Comma separated string of broker hostname:ports,
    # useful in many client configs.
    $brokers_string  = inline_template('<%= @brokers_config.keys.sort.map { |b| "#{b}:#{@brokers_config[b].fetch("port", 9092)}" }.join(",") %>')

    $jmx_port        = 9999

    # jmxtrans renders hostname metrics with underscores and
    # suffixed with the jmx port.  Build a graphite
    # wildcard to match these.
    # E.g. kafka1012.eqiad.wmnet -> kafka1012_eqiad_wmnet_9999
    $brokers_graphite_wildcard = inline_template('{<%= @brokers_array.join("_#{@jmx_port},").tr(".","_") + "_#{@jmx_port}" %>}')

    $zookeeper_hosts  = keys(hiera('zookeeper_hosts'))
    $zookeeper_chroot = "/kafka/${cluster_name}"
    $zookeeper_url    = inline_template("<%= @zookeeper_hosts.sort.join(',') %><%= @zookeeper_chroot %>")
}
