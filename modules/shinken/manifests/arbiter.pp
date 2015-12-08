# Class: shinken::arbiter
#
# Install, configure and ensure running for shinken arbiter daemon
#
# Description: The Arbiter is responsible for:
# - Loading, manipulating and dispatching the configuration
# - Validating the health of all other Shinken daemons
# - Issuing global directives to Shinken daemons (kill, activate-spare, etc.)
#
# Parameters:
#   $arbiter_name
#       Name of the arbiter. Defaults to fqdn
#   $listen_address
#       The address this daemon should be listening on
#   $spare
#       Whether this daemon is a spare or not
#   $timeout
#       Ping timeout
#   $data_timeout
#       Data send timeout
#   $max_check_attempts
#       If ping fails N or more, then the node is dead
#   $check_interval
#       Ping node every N seconds
#   $modules
#       An array of arbiter modules to enable.
#   $daemon_enabled
#       Whether the daemon should be enabled at all. Only useful in multi
#       arbiter configurations where the second one is marked as disabled (and
#       spare)
class shinken::arbiter(
    $arbiter_name       = $::fqdn,
    $listen_address     = $::ipaddress,
    $spare              = 0,
    $timeout            = 3,
    $data_timeout       = 120,
    $max_check_attempts = 3,
    $check_interval     = 60,
    $modules            = ['pickle-retention-arbiter'],
    $daemon_enabled     = 1,
) {
    # NOTE: we explicitly not pass conf_file here
    shinken::daemon { "arbiter-${arbiter_name}":
        daemon => 'arbiter',
        port   => 7770,
    }

    file { '/etc/shinken/shinken.cfg':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('shinken/shinken.cfg.erb'),
        require => Shinken::Daemon["arbiter-${arbiter_name}"],
    }

    file { "/etc/shinken/arbiters/${::fqdn}.cfg":
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('shinken/arbiter.cfg.erb'),
        tag     => 'shinken-arbiter',
        require => Shinken::Daemon["arbiter-${arbiter_name}"],
    }
    class { [
      'nagios_common::user_macros',
      'nagios_common::timeperiods',
      'nagios_common::notification_commands',
    ] :
        notify => Shinken::Daemon["arbiter-${arbiter_name}"],
    }
    # TODO: Figure out what to do with this
    class { '::icinga::naggen':    }

    # TODO: Clear this up
    include ::icinga::plugins
}
