# == Class profile::kafka::mirror::monitoring
#
define profile::kafka::mirror::monitoring(
    $prometheus_jmx_exporter_port = 7900,
) {
    $jmx_exporter_config_file = "/etc/kafka/mirror/$title/prometheus_jmx_exporter.yaml"

    # Use this in your JAVA_OPTS you pass to the Kafka MirrorMaker process
    $java_opts = "-javaagent:/usr/share/java/prometheus/jmx_prometheus_javaagent.jar=${::ipaddress}:${prometheus_jmx_exporter_port}:${jmx_exporter_config_file}"


    # Allow automatic generation of config on the Prometheus master
    prometheus::jmx_exporter_instance { $::hostname:
        address => $::ipaddress,
        port    => $prometheus_jmx_exporter_port,
    }

    $prometheus_nodes_ferm = join($prometheus_nodes, ' ')
    ferm::service { 'kafka-broker-jmx_exporter':
        proto  => 'tcp',
        port   => '7800',
        srange => "@resolve((${prometheus_nodes_ferm}))",
    }



    # Generate icinga alert if Kafka Server is not running.
    nrpe::monitor_service { "kafka-mirror-${mirror_maker_instance_name}":
        description   => "Kafka MirrorMaker ${mirror_maker_instance_name}",
        nrpe_command  => "/usr/lib/nagios/plugins/check_procs -c 1:1 -C java  --ereg-argument-array 'kafka.tools.MirrorMaker.+/etc/kafka/mirror/${mirror_maker_instance_name}/producer\\.properties'",
        require       => Confluent::Kafka::Mirror::Instance[$mirror_maker_instance_name],
    }
}
