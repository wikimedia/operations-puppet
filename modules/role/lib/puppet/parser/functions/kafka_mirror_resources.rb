# == Function: kafka_mirror_resources(hash sources, array destination)
#
# Allows to build a structure for use by confluent::kafka::mirrors
# from a simple declarative structure.
#
# Sources must be in the form { site => [cluster1, cluster2], site2 => [cluster1]}
# Destination must be a simple [cluster, site] array.
module Puppet::Parser::Functions
  newfunction(:kafka_mirror_resources, :type => rvalue) do |args|
    mirrors = {}
    # TODO: validation
    sources = args[0]
    destination = args[1]
    destination_brokers = function_kafka_config(destination)['brokers']['string'].split(',')
    sources.each do |site, clusters|
      clusters.each do |cluster|
        resource_title = "#{cluster}_#{site}_to_#{destination.join('_')}"
        mirrors[resource_title] = {
          'source_zookeeper_url' => function_kafka_config([cluster, site])['zookeeper']['url'],
          'destination_brokers'  => destination_brokers,
          'whitelist'            => "^#{site}[\._].+",
        }
      end
    end
    mirrors
  end
end
