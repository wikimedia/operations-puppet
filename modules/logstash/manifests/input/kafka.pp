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
# - $zk_connect: Zookeeper host and port (and optionally: chroot path).
#      Format: 'some.zookeeper.host:1234/chroot/path'. For more info, see:
#      https://www.elastic.co/guide/en/logstash/current/plugins-inputs-kafka.html
#
# == Sample usage:
#
#   logstash::input::kafka { 'some_topic':
#       zk_connect => 'some.zookeeper.host:1234/chroot/path',
#   }
#
define logstash::input::kafka(
    $ensure     = present,
    $priority   = 10,
    $tags       = [$title],
    $topic      = $title,
    $type       = 'kafka',
    $zk_connect = '',
) {
    logstash::conf { "input-kafka-${title}":
        ensure   => $ensure,
        content  => template('logstash/input/kafka.erb'),
        priority => $priority,
    }
}
