# vim:sw=4 ts=4 sts=4 et:

# = Define: logstash::input::kafka
#
# Configure logstash to collect input from a Kafka topic.
#
# == Parameters:
#
# - $ensure: Whether the config should exist. Default: present.
# - $priority: Configuration loading priority. Default: '10'.
# - $tags: Array of tags to be added to the logs. Default: [$title].
# - $topic: Kafka topic. Default: $title.
# - $topics_pattern: Kafka topic pattern. Default: None. Supersedes $topic if set.
# - $group_id: Kafka consumer group id. Default: None (use logstash implemented default of "logstash")
# - $type: Log type to be passed to Logstash. Default: 'kafka'.
# - $codec: Codec to decode input. Default 'plain'.
# - $bootstrap_servers: Kafka servers to boostrap from. This list should be
#      a string in the form of `host1:port1,host2:port2. For more info, see:
#      https://www.elastic.co/guide/en/logstash/current/plugins-inputs-kafka.html
# - $plugin_id: Name associated with Logstash metrics
# - $security_protocol: Security protocol to use, which can be either of PLAINTEXT,SSL,SASL_PLAINTEXT,SASL_SSL
#      must be set to SSL for ssl_truststore* configs to be set
#      see https://www.elastic.co/guide/en/logstash/current/plugins-inputs-kafka.html#plugins-inputs-kafka-security_protocol
# - $ssl_truststore_location: path to jks truststore file. Default: none. Requires $security_protocol = 'SSL'
# - $ssl_truststore_password: jks truststore password value. Default: none. Requires $security_protocol = 'SSL'
#
# == Sample usage:
#
#   logstash::input::kafka { 'some_topic':
#       boostrap_servers => 'kafka1001:9092,kafka1002:9092',
#   }
#
define logstash::input::kafka(
    $bootstrap_servers,
    $ensure                                                                          = present,
    $priority                                                                        = 10,
    $tags                                                                            = [$title],
    $topic                                                                           = $title,
    Optional[String] $topics_pattern                                                 = undef,
    $type                                                                            = 'kafka',
    String $codec                                                                    = 'plain',
    $plugin_id                                                                       = "input/kafka/${title}",
    Optional[Enum['PLAINTEXT','SSL','SASL_PLAINTEXT','SASL_SSL']] $security_protocol = undef,
    Optional[Stdlib::Unixpath] $ssl_truststore_location                              = undef,
    Optional[String] $ssl_truststore_password                                        = undef,
    Optional[String] $group_id                                                       = undef,
    Integer $consumer_threads                                                        = 1,
) {
    logstash::conf { "input-kafka-${title}":
        ensure   => $ensure,
        content  => template('logstash/input/kafka.erb'),
        priority => $priority,
    }
}
