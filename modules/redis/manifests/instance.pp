# == Define: redis::instance
#
# Provisions a Redis instance.
#
# === Parameters
#
# [*title*]
#   Instance name. To avoid collisions, this value must either be a TCP
#   port number or the absolute path to a UNIX socket. Defaults to the
#   resource title.
#
# [*settings*]
#   A map of Redis configuration directives to their desired value.
#   See <http://redis.io/topics/config> for documentation.
#
# [*map*]
#  A value can be a hash of settings for the various instances
#  we are defining at the same time, in the form of instance_name => settings.
#  Only overrides to what is the default in settings needs to be defined.
#
# [*allow_config_writes*]
#  If true, Redis is allowed to use the `CONFIG REWRITE` option. This is required
#  when using Redis Sentinel.
#
# === Examples
#
#  # Configure a Redis instance on TCP port 6379:
#  redis::instance { '6379':
#    settings => { maxmemory => '2mb' },
#  }
#
#  # Configure a Redis instance on UNIX socket:
#  redis::instance { '/var/run/redis-primary.sock':
#    settings => { maxmemory => '2mb' },
#  }
#
#  # Configure two instances, with 6380 being a slave
#  redis::instance { ['6379', '6380']:
#    settings => { maxmemory => '2mb', slaveof => undef},
#    map      => {
#      '6380'    => { 'slaveof' => '127.0.0.1 6379'}
#    }
#  }
#
define redis::instance(
    Wmflib::Ensure $ensure              = present,
    Hash           $settings            = {},
    Hash           $map                 = {},
    Boolean        $allow_config_writes = false,
) {

    require redis

    if $title =~ /^[1-9]\d*/ {
        # Listen on TCP port
        $instance_name = "tcp_${title}"
        $port          = $title
        $unixsocket    = ''
    } elsif $title =~ /^\/.*\.sock/ {
        # Listen on UNIX domain socket
        $instance_name = sprintf('unix_%s', basename($title, '.sock'))
        $port          = 0
        $unixsocket    = $title
    } else {
        fail('redis::instance title must be a TCP port or absolute path to UNIX socket.')
    }

    $dbname = "${::hostname}-${title}"
    $defaults = {
        pidfile        => "/var/lib/redis/${instance_name}.pid",
        logfile        => "/var/log/redis/${instance_name}.log",
        port           => $port,
        unixsocket     => $unixsocket,
        daemonize      => true,
        appendfilename => "${dbname}.aof",
        dbfilename     => "${dbname}.rdb",
    }

    # make the config file owned by root and read-only by default,
    # only when allow_config_writes is true (such as when redis-sentinel is in
    # use), make it owned by redis and allow writes by the owner
    # otherwise puppet and redis will continue to revert each other: T309014
    file { "/etc/redis/${instance_name}.conf":
        ensure  => $ensure,
        content => template('redis/instance.conf.erb'),
        owner   => $allow_config_writes.bool2str('redis', 'root'),
        group   => 'redis',
        mode    => $allow_config_writes.bool2str('0644', '0440'),
        notify  => Service["redis-instance-${instance_name}"],
        replace => !$allow_config_writes,
    }

    # Set the maximum number of open files to maxclients + 32
    # See https://redis.io/topics/clients for details
    # The default maxclient setting is 10000
    $maxclients = $settings['maxclients'] ? {
        undef   => 10000,
        default => $settings['maxclients']
    }

    $open_files = $maxclients + 32
    systemd::service { "redis-instance-${instance_name}":
        ensure  => $ensure,
        content => systemd_template('redis-instance'),
        restart => false,
    }
}
