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
    $ensure   = present,
    $settings = {},
    $map = {}
    ) {
    validate_ensure($ensure)
    validate_hash($settings)
    validate_hash($map)

    require ::redis

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


    file { "/etc/redis/${instance_name}.conf":
        ensure  => $ensure,
        content => template('redis/instance.conf.erb'),
        owner   => 'root',
        group   => 'redis',
        mode    => '0440',
    }

    base::service_unit { "redis-instance-${instance_name}":
        ensure    => $ensure,
        systemd   => systemd_template('redis-instance'),
        subscribe => File["/etc/redis/${instance_name}.conf"],
    }
}
