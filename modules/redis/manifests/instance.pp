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
#
define redis::instance(
    $ensure   = present,
    $settings = {}
) {
    conflicts(Class['redis::legacy'])

    validate_ensure($ensure)
    validate_hash($settings)

    include ::redis

    # Disable the system-global redis service that the redis-server
    # package configures by default.
    if ! defined(Service['redis-server']) {
        service { 'redis-server':
            ensure    => stopped,
            enable    => false,
            subscribe => Package['redis-server'],
        }
    }

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

    $defaults = {
        pidfile    => "/var/run/redis/${instance_name}.pid",
        logfile    => "/var/log/redis/${instance_name}.log",
        port       => $port,
        unixsocket => $unixsocket,
        daemonize  => false,
    }

    file { "/etc/redis/${instance_name}.conf":
        ensure  => $ensure,
        content => template('redis/instance.conf.erb'),
        owner   => 'root',
        group   => 'redis',
        mode    => '0440',
    }

    base::service_unit { "redis-instance-${instance_name}":
        ensure        => $ensure,
        template_name => 'redis-instance',
        systemd       => true,
        upstart       => true,
        subscribe     => File["/etc/redis/${instance_name}.conf"],
    }
}
