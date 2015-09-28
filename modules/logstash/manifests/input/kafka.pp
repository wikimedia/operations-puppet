# vim:sw=4 ts=4 sts=4 et:

# = Define: logstash::input::kafka
#
# Configure logstash to collect input from a Kafka topic.
#
# == Parameters:
#
# - $ensure: Whether the config should exist. Default: present.
# - $priority: Configuration loading priority. Default: '10'.
# - $tags: Array of tags to be added to the logs. Default: [].
# - $topic: Kafka topic.
# - $zk_connect: Zookeeper host and port (and optionally: chroot path).
#      Format: 'some.zookeeper.host:1234/chroot/path'. For more info, see:
#      https://www.elastic.co/guide/en/logstash/current/plugins-inputs-kafka.html
#
# == Sample usage:
#
#   logstash::input::kafka {
#       tags => ['system1', 'category2'],
#       topic => 'topic1',
#       zk_connect => 'some.zookeeper.host:1234/chroot/path',
#   }
#
define logstash::input::kafka(
    $ensure     = present,
    $priority   = 10,
    $tags       = [],
    $topic   = '',
    $zk_connect = '',
) {
    logstash::conf { "input-kafka-${title}":
        ensure   => $ensure,
        content  => template('logstash/input/kafka.erb'),
        priority => $priority,
    }
}
