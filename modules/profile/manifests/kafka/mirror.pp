# == Class profile::kafka::mirror
# Sets up an individual MirrorMaker instance to mirror from $source_cluster_name
# to $destination_cluster_name.  Consumer and Producer properties will automatically
# include proper max message bytes / batch size settings.  Any other MirrorMaker
# Consumer or Producer properties you need to set should be provided in $properties,
# with keys that match the confluent::kafka::mirror::instance define parameters.
#
# TODO:
# - TLS configuration
#
# == Parameters
# [*source_cluster_name*]
#   This will be passed to the kafka_config function to find the source cluster brokers.
#
# [*destination_cluster_name*]
#   This will be passed to the kafka_config function to find the destination cluster brokers.
#
# [*properties*]
#   Hash of extra properties to pass to confluent::kafka::mirror::instance.
#   Default: {}
#
# [*num_processes*]
#   Number of (systemd based) processes to spawn for this MirrorMaker.  Default: 1
#
# [*monitoring_enabled*]
#   If true, monitoring (via prometheus) will be enabled for this MirrorMaker instance.
#
# [*jmx_base_port*]
#   Starting port for JMX.  Each instantiated process will +1 to this port.
#   Default: 9900
#
# [*jmx_exporter_base_port*]
#   Starting port for Prometheus JMX exporter.  Each instantiated process will +1 to this port.
#   Only used if $monitoring_enabled is true.  Default: 7900
#
# [*message_max_bytes*]
#   Max Kafka message size.  Should be synchronized between all producers, brokers, and consumers.
#
# [*prometheus_nodes*]
#   Prometheus nodes that should be allowed to query the JMX exporter.
#
class profile::kafka::mirror(
    $source_cluster_name      = hiera('profile::kafka::mirror::source_cluster_name'),
    $destination_cluster_name = hiera('profile::kafka::mirror::destination_cluster_name'),
    $properties               = hiera('profile::kafka::mirror::properties', {}),
    $num_processes            = hiera('profile::kafka::mirror::num_processes', 1),
    $monitoring_enabled       = hiera('profile::kafka::mirror::monitoring_enabled', true),
    $jmx_base_port            = hiera('profile::kafka:mirror:jmx_base_port', 9900),
    $jmx_exporter_base_port   = hiera('profile::kafka::mirror:jmx_exporter_base_port', 7900),
    $message_max_bytes        = hiera('kafka_message_max_bytes'),
    $prometheus_nodes         = hiera('prometheus_nodes'),
) {
    $source_config            = kafka_config($source_cluster_name)
    $destination_config       = kafka_config($destination_cluster_name)

    # This is the name of the logical MirrorMaker instance.  It will be used
    # for the consumer group.id.  Each individual process belonging to this will
    # be named $mirror_instance@$process_num.
    $mirror_instance = "${source_config['name']}_to_${destination_config['name']}"

    # Iterate and instantiate $num_processes MirrorMaker processes using these configs.
    range(0, $num_processes - 1).each |$process| {

        # Use the names from the config hashes, rather than as passed in, since names passed in
        # might not be fully suffixed with datacenter name.
        $mirror_name = "${mirror_instance}@${process}"

        if $monitoring_enabled {
            $prometheus_jmx_exporter_port = $jmx_exporter_base_port + $process
            $jmx_exporter_config_file = "/etc/kafka/mirror/${mirror_name}/prometheus_jmx_exporter.yaml"

            # Use this in your JAVA_OPTS you pass to the Kafka MirrorMaker process
            $java_opts = "-javaagent:/usr/share/java/prometheus/jmx_prometheus_javaagent.jar=${::ipaddress}:${prometheus_jmx_exporter_port}:${jmx_exporter_config_file}"

            # Declare a prometheus jmx_exporter instance.
            # This will render the config file, declare the jmx_exporter_instance,
            # and configure ferm.
            profile::prometheus::jmx_exporter { "kafka_mirror_${$mirror_name}_${::hostname}":
                hostname         => $::hostname,
                port             => $prometheus_jmx_exporter_port,
                prometheus_nodes => $prometheus_nodes,
                config_file      => $jmx_exporter_config_file,
                content          => template('profile/kafka/mirror_maker_prometheus_jmx_exporter.yaml.erb'),
            }

            # Generate icinga alert if Kafka Server is not running.
            nrpe::monitor_service { "kafka-mirror-${mirror_name}":
                description  => "Kafka MirrorMaker ${mirror_name}",
                nrpe_command => "/usr/lib/nagios/plugins/check_procs -c 1:1 -C java  --ereg-argument-array 'kafka.tools.MirrorMaker.+/etc/kafka/mirror/${mirror_name}/producer\\.properties'",
                require      => Confluent::Kafka::Mirror::Instance[$mirror_name],
            }

            # More alerts can be added by declaring
            # profile::kafka::mirror::alerts { $mirror_name: }
            # elsewhere, usually in profile::prometheus::alerts.
        }
        else {
            $java_opts = ''
        }

        # The requests not only contain the message but also a small metadata overhead.
        # So if we want to produce a kafka_message_max_bytes payload the max request size should be
        # a bit higher. The 48564 value isn't arbitrary - it's the difference between default
        # message.max.size and default max.request.size
        $producer_request_max_size = $message_max_bytes + 48564
        $producer_properties = {
            'max.request.size' => $producer_request_max_size,
        }

        $consumer_properties = {
            # RoundRobin results in more balanced consumer assignment when dealing
            # with many single partition topics.
            'partition.assignment.strategy' => 'org.apache.kafka.clients.consumer.RoundRobinAssignor',
            'max.partition.fetch.bytes'     => $producer_request_max_size
        }

        # Minimum defaults for configuring a MirrorMaker instance.
        $default_parameters = {
            'source_brokers'      => split($source_config['brokers']['string'], ','),
            'destination_brokers' => split($destination_config['brokers']['string'], ','),
            'producer_properties' => $producer_properties,
            'consumer_properties' => $consumer_properties,
            'java_opts'           => $java_opts,
            # TODO: the following should be removed once we no longer use jmxtrans for
            # mirror maker monitoring and these params are removed from
            # confluent::kafka::mirror::instance
            'monitoring_enabled'  => false,
            'jmx_port'            => $jmx_base_port + $process,
            'group_id'            => "kafka-mirror-${mirror_instance}",
        }

        # This hash will be passed to confluent::kafka::mirror::instance.
        # Use deep_merge because producer and consumer properties are also hashes.
        $mirror_parameters = deep_merge(
            $default_parameters,
            $properties
        )

        # Create the mirror instance using create_resources.  This allows us to pass parameters
        # from hiera, with some sane defaults, to the mirror::instance without declaring
        # every possible mirror::instance parameter here.  Any that aren't defined in $mirror_parameters
        # will just use the confluent::kafka::mirror::instance defaults.
        # If we didn't do this, we'd have to add around 8 more paramters to this profile
        # now, and possibly more as needed later.
        create_resources(
            'confluent::kafka::mirror::instance',
            { "${mirror_name}" => $mirror_parameters }
        )
    }
}
