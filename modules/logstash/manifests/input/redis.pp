# = Class: logstash::input::redis
#
# Configure logstash to collect input from a Redis server
#
# == Parameters:
# - $host: Redis server to contact
# - $port: Redis server port
# - $data_type: Type of communication: 'list', 'channel', 'pattern_channel'
# - $key: Name of a redis list or channel
# - $priority: Configuration loading priority. Default '10'.
# - $ensure: Whether the config should exist.
#
# == Sample usage:
#
#   class { 'logstash::input::redis':
#       host => '127.0.0.1',
#       key  => 'logstash',
#   }
#
class logstash::input::redis(
    $host       = '127.0.0.1',
    $port       = '6379',
    $data_type  = 'list',
    $key        = 'logstash'
    $priority   = '10',
    $ensure     = present,
) {
    require logstash

    @logstash::conf{ 'redis-input':
        content  => template('logstash/input/redis.erb'),
        priority => $priority,
        ensure   => $ensure,
    }
}
# vim:sw=4 ts=4 sts=4 et:
