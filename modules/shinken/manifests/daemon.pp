# Class: shinken::daemon
#
# This class should not be instantiated on its own. It is mostly here to
# deduplicate code
#
# Parameters:
#   $daemon
#       Name of the daemon. Valid options:
#           broker, poller, reactionner, receiver, scheduler
#   $conf_file
#       The path to the conf file
#   $ensure
#
# Actions:
#       Install shinken daemon package, configure, ensure running
#
# Requires:
#
# Sample Usage:
#   Do not please use it directly
#
class shinken::daemon(
    $daemon,
    $conf_file,
    $ensure='present',
    ) {

    package { "shinken-${daemon}":
        ensure => $ensure,
    }

    file { $conf_file :
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template("shinken/${daemon}d.ini.erb"),
    }

    $service_state = $ensure ? {
        'present' => 'running',
        'absent'  => 'stoppped',
        default   => 'running',
    }

    service { "shinken-${daemon}":
        ensure  => $service_state,
    }
}
