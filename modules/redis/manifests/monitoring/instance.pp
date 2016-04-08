# === define redis::monitoring::instance
#
# Define used for monitoring a redis instance
#
# Accepts, for ease of use, the same parameters as the redis::instance define
#

define redis::monitoring::instance(
    $ensure = present,
    $settings = {},
    $map = {},
    $lag_warning = 60,
    $lag_critical = 600,
) {

    require nagios_common::commands

    $port = $title
    # Check if slaveof in settings, and not empty
    if has_key($settings, 'slaveof') {
        $slaveof = $settings['slaveof']
    } elsif (has_key($map, $title) and has_key($map[$title], 'slaveof')) {
        $slaveof = $map[$title]['slaveof']
    }
    else {
        $slaveof = undef
    }

    if ($slaveof) {
        monitoring::service{ "redis.tcp_${port}":
            description   => 'Redis status',
            check_command => "check_redis_replication!${title}!${lag_warning}!${lag_critical}"

        }
    } else {
        monitoring::service{ "redis.tcp_${port}":
            description   => 'Redis status',
            check_command => "check_redis!${title}"
        }
    }
}
