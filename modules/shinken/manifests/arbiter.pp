# Class: shinken::arbiter
#
#    ## Optional
#    timeout             <%= @timeout %>; Ping timeout
#    data_timeout        <%= @data_timeout %>; Data send timeout
#    max_check_attempts  <%= @max_check_attempts %>; If ping fails N or more, then the node is dead
#    check_interval      <%= @check_interval %>; Ping node every N seconds
# Install, configure and ensure running for shinken broker daemon 
class shinken::arbiter(
    $arbiter_name        = $::fqdn,
    $listen_address      = $::ipaddress,
    $spare               = 0,
    $timeout             = 3,
    $data_timeout        = 120,
    $max_check_attempts  = 3,
    $check_interval      = 60,
    $modules             = ['pickle-retention-arbiter'],
    $daemon_enabled      = 1,
) {
    # NOTE: we explicitly not pass conf_file here
    shinken::daemon { "arbiter-${::fqdn}":
        daemon      => 'arbiter',
        port        => 7770,
    }

    file { '/etc/shinken/shinken.cfg':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('shinken/shinken.cfg.erb'),
    }

    file { '/etc/shinken/config':
        ensure => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///modules/shinken/config',
        recurse => true,
        purge   => true,
        force   => true,
    }

    file { "/etc/shinken/arbiters/${::fqdn}.cfg":
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('shinken/arbiter.cfg.erb'),
        tag     => 'shinken-arbiter',
    }
    class { [
      'nagios_common::user_macros',
      'nagios_common::timeperiods',
      'nagios_common::notification_commands',
    ] :
        notify => Shinken::Daemon["arbiter-${::fqdn}"],
    }
    # TODO: Figure out what to do with this
    class { '::icinga::naggen':    }

    # TODO: Clear this up
    include ::icinga::plugins
}
