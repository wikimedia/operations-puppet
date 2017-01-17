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

    validate_ensure($ensure)
    validate_hash($settings)
    validate_hash($map)

    if $title =~ /^[1-9]\d*/ {
        # Listen on TCP port
        $instance_name = "tcp_${title}"
        $port          = $title
    } else {
        fail('redis::monitoring::instance title must be a TCP port.')
    }

    # Check if slaveof in settings, and not empty
    if has_key($settings, 'slaveof') {
        $slaveof = $settings['slaveof']
    } elsif (has_key($map, $port) and has_key($map[$port], 'slaveof')) {
        $slaveof = $map[$title]['slaveof']
    }
    else {
        $slaveof = undef
    }
    if has_key($map, $port) and has_key($map[$port], 'masterauth') {
        $password = $map[$port]['masterauth']
    }
    if $password {
        $repl_command = "check_redis_replication!${port}!${lag_warning}!${lag_critical}!${password}"
        $check_command = "check_redis!${port}!${password}"
    } else {
        $repl_command = "check_redis_replication!${port}!${lag_warning}!${lag_critical}"
        $check_command = "check_redis!${port}"
    }

    if ($slaveof) {
        monitoring::service{ "redis.${instance_name}":
            description    => "Redis status ${instance_name}",
            check_command  => $repl_command,
            retry_interval => 2,

        }
    } else {
        monitoring::service{ "redis.${instance_name}":
            description   => "Redis status ${instance_name}",
            check_command => $check_command,
        }
    }
}
