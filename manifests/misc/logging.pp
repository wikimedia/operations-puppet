# misc/logging.pp
# any logging hosts

class misc::logging::socat {
    package { 'socat':
        ensure => 'installed',
    }
}

# == Define misc::logging::multicast-relay
# Sets up a UDP unicast to multicast relay process.
#
# == Parameters:
# $listen_port       - The port on which to accept UDP traffic for relay.
# $destination_ip
# $destination_port
# $multicast         - boolean.  Default false.  If true, the received traffic will be relayed to multicast group specified by $destination_ip and $destination_port.
define misc::logging::relay(
    $listen_port,
    $destination_ip,
    $destination_port,
    $multicast = false
)
{
    require misc::logging::socat

    # Configure and start the upstart job for
    # luanching the socat multicast relay daemon.
    if $multicast {
        $daemon_name = "${title}-multicast-relay"
    }
    else {
        $daemon_name = "${title}-unicast-relay"
    }

    # Create symlink
    file { "/etc/init.d/${daemon_name}":
        ensure => 'link',
        target => '/lib/init/upstart-job',
    }

    file { "/etc/init/${daemon_name}.conf":
        content => template('misc/logging-relay.upstart.conf.erb'),
    }

    service { $daemon_name:
        ensure    => running,
        require   => Package['socat'],
        subscribe => File["/etc/init/${daemon_name}.conf"],
        provider  => 'upstart',
    }
}
