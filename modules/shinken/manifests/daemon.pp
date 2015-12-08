# define: shinken::daemon
#
# This define should not be instantiated on its own. It is mostly here to
# deduplicate code
#
# Parameters:
#   $daemon
#       Name of the daemon. Valid options:
#           broker, poller, reactionner, receiver, scheduler
#   $conf_file
#       The path to the conf file
#   $listen_address
#       The IP address to listen on
#   $ensure
#       present or absent
#
# Actions:
#       Configure shinken daemons, ensure running
#
# Requires:
#   Class shinken
#
# Sample Usage:
#   Do not please use it directly
#
define shinken::daemon(
    $daemon,
    $port,
    $conf_file      = undef,
    $listen_address = undef,
    $ensure         = 'present',
) {

    include ::shinken

    # Puppet's implicit dependencies mean we don't need a require for parent dir
    if $conf_file {
        file { $conf_file :
            ensure  => $ensure,
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            content => template('shinken/daemond.ini.erb'),
            require => File[$conf_file],
            notify  => Service["shinken-${daemon}"],
        }
    }

    service { "shinken-${daemon}":
        ensure  => ensure_shinken($ensure),
        require => Class['shinken'],
    }
}
