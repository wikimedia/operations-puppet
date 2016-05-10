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
# the 'kafka_clusters' and 'zookeeper_hosts' hashes in Hiera and reformats them
# to provide a more convenient output, suitable for usage in Puppet modules.
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
#       'hosts'  => # array of defined zookeeper hosts
#       'chroot' => # the zookeeper chroot for the cluster
#       'url'    => # the connection string to use
#     }
#   }

module Puppet::Parser::Functions
  newfunction(:kafka_config, :type => :rvalue, :arity => -2) do |args|
    fqdn = lookupvar('::fqdn').to_s
    clusters = function_hiera(['kafka_clusters', {}])
    cluster_name = clusters.key?(args[0]) ? args[0] : function_kafka_cluster_name(args)
    zk_hosts = function_hiera(['zookeeper_hosts', [fqdn]])
    zk_hosts = zk_hosts.keys.sort if zk_hosts.kind_of?(Hash)
    cluster = clusters[cluster_name] || {
      'brokers' => {
        fqdn => { 'id' => '1' }
      }
    }
    brokers = cluster['brokers']
    jmx_port = '9999'
    {
      'name'      => cluster_name,
      'brokers'   => {
        'hash'     => brokers,
        'array'    => brokers.keys,
        # list of comma-separated host:port broker pairs
        'string'   => brokers.map { |host, conf| "#{host}:#{conf['port'] || 9092}" }.sort.join(','),
        # list of comma-separated host_9999 broker pairs used as graphite wildcards
        'graphite' => "{#{brokers.keys.map { |b| "#{b.tr '.', '_'}_#{jmx_port}" }.join(',')}}",
        'size'     => brokers.keys.size
      },
      'jmx_port'  => jmx_port,
      'zookeeper' => {
        'hosts'  => zk_hosts,
        'chroot' => "/kafka/#{cluster_name}",
        'url'    => "#{zk_hosts.join(',')}/kafka/#{cluster_name}"
      }
    }
  end
end
