# This file provides the definition for instantiating a testreduce client
#
# === Parameters
#
# [*instance_name*]
#   Name of the testreduce client service
#
define testreduce::client(
    $instance_name
) {
    file { "/etc/testreduce/${instance_name}.config.js":
        source => "puppet:///modules/testreduce/${instance_name}.config.js",
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        notify => Service[$instance_name],
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
