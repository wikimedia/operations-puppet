# This file provides the definition for instantiating a testreduce client
#
# === Parameters
#
# [*instance_name*]
#   Name of the testreduce client service
#
define testreduce::client(
    $instance_name,
    $parsoid_port,
) {
    file { "/etc/testreduce/${instance_name}.config.js":
        content => template("testreduce/${instance_name}.config.js.erb"),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service[$instance_name],
    }

    file { "/lib/systemd/system/${instance_name}.service":
        source => "puppet:///modules/testreduce/${instance_name}.systemd.service",
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        before => Service[$instance_name],
    }

    service { $instance_name:
    }
}
