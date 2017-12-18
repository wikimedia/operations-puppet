# == Function: kafka_config(string cluster_prefix[, string site])
#
# Reworks various variables to be in a format suitable for supplying them
# to the kafka module classes. If the optional site argument is given, the
# actual site where the function is evaluated is ignored
#
# === Parameters
#
# [*cluster_prefix*]
#   The full Kafka cluster name to use or its prefix, as understood by the
#   'kafka_cluster_name' function. This argument is interpreted as the full
#   cluster name if the ::kafka_clusters Hiera hash contains a key with the
#   given name. Otherwise, 'kafka_cluster_name' is invoked. Required.
#
# [*site*]
#   The site for which to return the configuration. Default: $::site
#
# === Usage
#
#   $config = kafka_config($prefix)
#
# This function retrieves the full cluster name using the given prefix (and
# optionally site) using the 'kafka_cluster_name' function. Then, it consults
# the 'kafka_clusters' and 'zookeeper_clusters' hashes in Hiera and reformats
# them to provide a more convenient output, suitable for usage in Puppet
# modules.
#
# It returns the config for a Kafka cluster in the following format:
#
#   {
#     'name'      => # full Kafka cluster name
#     'brokers'   => {
#       'hash'     => # original brokers definition as seen in Hiera
#       'array'    => # array of brokers' FQDNs
#       'string'   => # comma-separated list of host:port broker pairs
#       'graphite' => # comma-separated list of host_9999 broker pairs
#       'size'     => # number of brokers
#     }
#     'jmx_port'  => # the JMX port (9999)
#     'zookeeper' => {
#       'name'   => # Zookeeper cluster name used by this Kafka cluster
#       'hosts'  => # array of defined zookeeper hosts
#       'chroot' => # the zookeeper chroot for the cluster
#       'url'    => # the connection string to use
#     }
#   }

module Puppet::Parser::Functions
  newfunction(:kafka_config, :type => :rvalue, :arity => -2) do |args|
    fqdn = lookupvar('::fqdn').to_s
    clusters = call_function(:hiera, ['kafka_clusters', {}])
    cluster_name = clusters.key?(args[0]) ? args[0] : function_kafka_cluster_name(args)

    cluster = clusters[cluster_name] || {
      'brokers' => {
        fqdn => { 'id' => '1' }
      }
    }
    brokers = cluster['brokers']

    # Get this Kafka cluster's zookeeper cluster name from the cluster config.
    zk_cluster_name = cluster['zookeeper_cluster_name']

    # Lookup all zookeeper clusters config
    zk_clusters = call_function(:hiera, ['zookeeper_clusters'])

    # These are the zookeeper hosts for this kafka cluster.
    zk_hosts = zk_clusters[zk_cluster_name]['hosts'].keys.sort

    default_port = 9092
    default_ssl_port = 9093
    jmx_port = '9999'

    config = {
      'name'      => cluster_name,
      'brokers'   => {
        'hash'       => brokers,
        # array of broker hostnames without port.  TODO: change this to use host:port?
        'array'      => brokers.keys.sort,
        # string list of comma-separated host:port broker
        'string'     => brokers.map { |host, conf| "#{host}:#{conf['port'] || default_port}" }.sort.join(','),

        # array host:ssl_port brokers
        'ssl_array'  => brokers.map { |host, conf| "#{host}:#{conf['ssl_port'] || default_ssl_port}" }.sort
        # string list of comma-separated host:ssl_port brokers
        'ssl_string' => brokers.map { |host, conf| "#{host}:#{conf['ssl_port'] || default_ssl_port}" }.sort.join(','),

        # list of comma-separated host_9999 broker pairs used as graphite wildcards
        'graphite'   => "{#{brokers.keys.map { |b| "#{b.tr '.', '_'}_#{jmx_port}" }.sort.join(',')}}",
        'size'       => brokers.keys.size
      },
      'jmx_port'  => jmx_port,
      'zookeeper' => {
        'name'   => zk_cluster_name,
        'hosts'  => zk_hosts,
        'chroot' => "/kafka/#{cluster_name}",
        'url'    => "#{zk_hosts.join(',')}/kafka/#{cluster_name}"
      }
    }

    if cluster.key?('api_version')
      config['api_version'] = cluster['api_version']
    else
      config['api_version'] = nil
    end

    config
  end
end
