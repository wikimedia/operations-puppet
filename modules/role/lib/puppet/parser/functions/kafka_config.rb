# == Function: kakfa_config(string cluster_prefix[, string site])
#
# Reworks various variables to be in a format suitable for supplying them
# to the kafka module classes. If the optional site argument is given, the
# actual site where the function is evaluated is ignored
#

module Puppet::Parser::Functions
  newfunction(:kafka_config, :type => :rvalue, :arity => -2) do |args|
    cluster_name = function_kafka_cluster_name(args)
    clusters = function_hiera(['kafka_clusters', {}])
    zk_hosts = function_hiera(['zookeeper_hosts'])
    zk_hosts = zk_hosts.keys.sort if zk_hosts.kind_of?(Hash)
    cluster = clusters[cluster_name] || {
      'brokers' => {
        lookupvar('fqdn').to_s => { 'id' => '1' }
      }
    }
    brokers = cluster['brokers']
    jmx_port = 9999
    {
      'name'      => cluster_name,
      'brokers'   => {
        'hash'     => brokers,
        'array'    => brokers.keys,
        'string'   => brokers.map { |host, port| "#{host}:#{port || 9092}" }.sort.join(','),
        'graphite' => brokers.keys.map { |b| "#{b.tr '.', '_'}_#{jmx_port}" }.join(','),
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
