# misc/logging.pp
# any logging hosts

# == Class misc::syslog-server
#
# Setup syslog-ng as a cluster wide syslog receiver.
#
# == Parameters:
#
# $config - Type of configuration to apply (nfs, network). Default 'nfs'
# $basepath - Path where to write logs to, without trailing slash.
#             Default: '/home/wikipedia/syslog'
#
class misc::syslog-server($config='nfs', $basepath='/home/wikipedia/syslog') {

    system::role { 'misc::syslog-server': description => "central syslog server (${config})" }

    package { 'syslog-ng':
        ensure => latest,
    }

    file { '/etc/syslog-ng/syslog-ng.conf':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template("syslog-ng/syslog-ng.conf.${config}.erb"),
        require => Package['syslog-ng'],
    }

    # FIXME: handle properly
    if $config == 'nfs' {
        file { '/etc/logrotate.d/remote-logs':
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            content => template('syslog-ng/remote-logs.erb'),
        }

        exec { 'create_syslog_basepath':
            command => "/bin/mkdir -p ${basepath}",
            creates => $basepath,
        }
        file { $basepath:
            ensure  => directory,
            require => Exec['create_syslog_basepath'],
            owner   => 'root',
            group   => 'root',
            mode    => '0755',
        }
    }

    service { 'syslog-ng':
        ensure    => running,
        require   => [
            Package['syslog-ng'],
            File['/etc/syslog-ng/syslog-ng.conf'],
        ],
        subscribe => File['/etc/syslog-ng/syslog-ng.conf'],
    }
}

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
    # Note: Not using generic::upstart_job define here since
    # it doesn't support using ERb templates.

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
