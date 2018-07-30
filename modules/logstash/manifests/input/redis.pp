# vim:sw=4 ts=4 sts=4 et:

# = Define: logstash::input::redis
#
# Configure logstash to collect input from a Redis server
#
# == Parameters:
# - $ensure: Whether the config should exist.
# - $host: Redis server to contact. Default 127.0.0.1
# - $port: Redis server port. Default 6379
# - $data_type: Type of communication: 'list', 'channel', 'pattern_channel'.
#     Default 'list'
# - $key: Name of a redis list or channel. Default 'logstash'
# - $password: Password to authenticate with. Default undef.
# - $priority: Configuration loading priority. Default '10'.
# - $plugin_id: Name associated with Logstash metrics
#
# == Sample usage:
#
#   logstash::inputs::redis { 'redis':
#       host => '127.0.0.1',
#       key  => 'logstash',
#   }
#
define logstash::input::redis(
    $ensure     = present,
    $host       = '127.0.0.1',
    $port       = 6379,
    $data_type  = 'list',
    $key        = 'logstash',
    $password   = undef,
    $priority   = 10,
    $plugin_id  = "input/redis/${port}",
) {
    logstash::conf { "input-redis-${title}":
        ensure   => $ensure,
        content  => template('logstash/input/redis.erb'),
        priority => $priority,
    }
}
