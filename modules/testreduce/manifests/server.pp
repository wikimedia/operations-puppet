# This file provides the definition for instantiating a testreduce server
#
# === Parameters
#
# [*instance_name*]
#   Name of the testreduce service
#
# [*db_name*]
#   Database name for storing results.
#
# [*db_user*]
#   Database user.
#
# [*db_host*]
#   MySQL host. Default: 'localhost'.
#
# [*db_port*]
#   MySQL port. Default: 3306.
#
# [*coord_port*]
#   The result aggregator will listen on this port. Default: 8002.
#
# [*webapp_port*]
#   The user-facing webapp that displays test results will listen on
#   this port. Default: 8003.
#
define testreduce::server(
    $instance_name,
    $db_name,
    $db_user,
    $db_pass,
    $db_host     = 'localhost',
    $db_port     = 3306,
    $coord_port  = 8002,
    $webapp_port = 8003,
) {
    file { "/etc/testreduce/${instance_name}.settings.js":
        content => template("testreduce/${instance_name}.settings.js.erb"),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service[$instance_name],
    }

    file { "/etc/init/${instance_name}.conf":
        source => "puppet:///modules/testreduce/${instance_name}.upstart.conf",
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        notify => Service[$instance_name],
    }

    service { $instance_name:
        ensure   => running,
        provider => upstart,
    }
}
