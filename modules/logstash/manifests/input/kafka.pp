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
# - $type: Log type to be passed to Logstash. Default: 'kafka'.
# - $bootstrap_servers: Kafka servers to boostrap from. This list should be
#      a string in the form of `host1:port1,host2:port2. For more info, see:
#      https://www.elastic.co/guide/en/logstash/current/plugins-inputs-kafka.html
#
# == Sample usage:
#
#   logstash::input::kafka { 'some_topic':
#       boostrap_servers => 'kafka1001:9092,kafka1002:9092',
#   }
#
define logstash::input::kafka(
    $bootstrap_servers,
    $ensure            = present,
    $priority          = 10,
    $tags              = [$title],
    $topic             = $title,
    $type              = 'kafka',
) {
    logstash::conf { "input-kafka-${title}":
        ensure   => $ensure,
        content  => template('logstash/input/kafka.erb'),
        priority => $priority,
    }
}
