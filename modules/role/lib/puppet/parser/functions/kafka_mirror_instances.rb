# == Function: kafka_mirror_instances(hash source_clusters, array destination_cluster)
#
# Allows to build a structure for use by confluent::kafka::mirrors
# (and create_resources) from a simple declarative structure.
#
# === Parameters
#
# [*source_clusters*]
#    A hash of the form
#    { site => [prefix1, prefix2, ...], site2 => [prefix1], ... }
#
# [*destination_cluster*]
#    Either a string prefix cluster name, or a two element array of [prefix,
#    site].  This will be passed to the kafka_config and ultimately the
#    kafka_cluster_name functions.  All mirror resource hashes
#    returned by this function will be configured to mirror into this cluster.
#
# == Usage
# # Return a resource hash suitable for passing to
# # ::confluent::kafka::mirrors that will create 4 MirrorMaker
# # instances consuming from clusterA-eqiad, clusterB-eqiad, clusterA-codfw
# # and clusterC-codfw into aggregate-eqiadA cluster, and blacklisting
# # any topics that start with 'skip'.
#
# kafka_mirror_instances(
#    # source_clusters
#    {
#       'eqiad' => ['clusterA', 'clusterB'],
#       'codfw' => ['clusterA', 'clusterC']
#    },
#    # destination_clusters
#    ['aggregate', 'eqiad']
# )
#
# == Usage with ::confluent::kafka::mirrors
#
# class { '::confluent::kafka::mirrors':
#   mirrors => kafka_mirror_instances({'eqiad' => ['main']}, ['main', 'codfw']),
#   mirror_defaults => { 'blacklist' => '^skip_these_topics.+', ... },
# }
#
module Puppet::Parser::Functions
    newfunction(:kafka_mirror_instances, :type => rvalue) do |args|
        mirrors = {}

        raise(Puppet::ParseError, "kafka_mirror_instances(): Wrong number of arguments " +
          "given (#{args.size} for 2)") if (args.size < 2 or args.size > 3)

        source_clusters = args[0]
        unless source_clusters.is_a?(Hash)
          raise(Puppet::ParseError, 'kafka_mirror_instances(): source_clusters should be a hash')
        end

        # destination_cluster can be a string with the cluster prefix, or a 2
        # element array with [prefix, site].  Make sure it is an Array either way.
        # This variable can be passed to the kafka_config function.
        destination_cluster      = Array(args[1])
        unless destination_cluster.is_a?(Array)
          raise(Puppet::ParseError, 'kafka_mirror_instances(): destination_cluster should be an array or a string prefix')
        end

        destination_cluster_name = function_kafka_cluster_name(destination_cluster)
        destination_brokers      = function_kafka_config(destination_cluster)['brokers']['string'].split(',')

        # Each mirror::instance will be auto-assigned a unique jmx_port,
        # incrementally starting with this port.
        incremental_jmx_port = 9951

        source_clusters.keys.sort.each do |prefix|
            sites = source_clusters[prefix]
            sites.each do |site|
                source_cluster        = [prefix, site]
                source_cluster_name   = function_kafka_cluster_name(source_cluster)
                source_cluster_config = function_kafka_config(source_cluster)

                # mirror::instance title, e.g. main-eqiad_to_main-codfw.
                title = "#{source_cluster_name}_to_#{destination_cluster_name}"

                # Pick a jmx_port unique between all of these
                # configured instances.
                jmx_port = incremental_jmx_port
                incremental_jmx_port += 1

                mirrors[title] = {
                    'source_zookeeper_url' => source_cluster_config['zookeeper']['url'],
                    'destination_brokers'  => destination_brokers,
                    'jmx_port'             => jmx_port
                }
            end
        end

        mirrors
    end
end