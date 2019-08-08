# This file provides the definition for instantiating a testreduce client
#
# === Parameters
#
# [*instance_name*]
#   Name of the testreduce client service
#
# [*parsoid_port*]
#   Port number on localhost when using Parsoid/JS
#
# [*use_parsoid_php*]
#   Whether to use Parsoid/PHP (true) or Parsoid/JS (false)
#
define testreduce::client(
    $instance_name,
    Stdlib::Port $parsoid_port,
    Boolean $use_parsoid_php,
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
        ensure => running,
    }
}
