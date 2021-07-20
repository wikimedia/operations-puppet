# = Define: logstash::output::kafka
#
# output logstash messages to a Kafka topic.
#
# == Parameters:
#
# - $ensure: Whether the config should exist. Default: present.
# - $priority: Configuration loading priority. Default: '10'.
# - $topic: Kafka topic. Default: $title.
# - $codec: Codec to encode output. Default 'plain'.
# - $bootstrap_servers: Kafka servers to bootstrap from. This list should be
#      a string in the form of `host1:port1,host2:port2.
# - $plugin_id: Name associated with Logstash metrics
# - $security_protocol: Security protocol to use, which can be either of PLAINTEXT,SSL,SASL_PLAINTEXT,SASL_SSL
#      must be set to SSL for ssl_truststore* configs to be set
# - $ssl_truststore_location: path to jks truststore file. Default: none. Requires $security_protocol = 'SSL'
# - $ssl_truststore_password: jks truststore password value. Default: none. Requires $security_protocol = 'SSL'
# - $guard_condition: Logstash condition to require to pass events to output.
#       Default undef.
#
# == Sample usage:
#
#   logstash::output::kafka { 'some_topic':
#       bootstrap_servers => 'kafka1001:9092,kafka1002:9092',
#   }
#
# TODO: Make this work with $kafka_cluster_name and kafka_config like
# logstash::input::kafka does.
define logstash::output::kafka(
    $bootstrap_servers,
    $ensure                                                 = present,
    $priority                                               = 10,
    $topic                                                  = $title,
    String $codec                                           = 'plain',
    $plugin_id                                              = "output/kafka/${title}",
    $guard_condition                                        = undef,
    Stdlib::Unixpath $ssl_truststore_location               = undef,
    String $ssl_truststore_password                         = undef,
    Optional[String] $ssl_endpoint_identification_algorithm = undef,
) {
    logstash::conf { "output-kafka-${title}":
        ensure   => $ensure,
        content  => template('logstash/output/kafka.erb'),
        priority => $priority,
    }
}
