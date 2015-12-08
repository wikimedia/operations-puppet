# Class: shinken::arbiter::daemon
#
# Populate configurations for daemons an arbiter should talk to
#
# Parameters:
#   $daemon_type
#       Either of 'broker', 'scheduler', 'reactionner', 'poller'
#   $address
#       The address for the arbiter to connect to
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
#       An array of modules to enable.
#   $daemon_config
#       A hash with the extra daemon configuration required. Varies per daemon,
#       look at shinken documentation
define shinken::arbiter::daemon(
    $daemon_type,
    $address,
    $daemon_name        = $title,
    $spare              = 0,
    $realm              = 'All',
    $timeout            = 3,
    $data_timeout       = 120,
    $max_check_attempts = 3,
    $check_interval     = 60,
    $modules            = [],
    $daemon_config      = undef,
) {
    include ::shinken::arbiter

    if $daemon_config {
        validate_hash($daemon_config)
    }

    $port = $daemon_type ? {
        'broker'      => 7772,
        'scheduler'   => 7768,
        'reactionner' => 7769,
        'poller'      => 7771,
        default       => undef,
    }

    if ! $port {
        fail('Wrong daemon_type specified for shinken::arbiter::daemon $title')
    }
    file { "/etc/shinken/${daemon_type}s/${daemon_name}.cfg":
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('shinken/daemon.cfg.erb'),
        notify  => Class['shinken::arbiter'],
    }
}
