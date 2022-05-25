# SPDX-License-Identifier: Apache-2.0
# This file provides the definition for instantiating a testreduce client
#
# === Parameters
#
# [*instance_name*]
#   Name of the testreduce client service
#
# [*service_ensure*]
#   Should the service be 'running' or 'stopped'.
#   Default: 'running'
#
# [*parsoid_port*]
#   Port number on localhost when using Parsoid/JS
#
define testreduce::client(
    String $instance_name,
    Stdlib::Port $parsoid_port,
    Stdlib::Ensure::Service $service_ensure = 'running',
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
        ensure => $service_ensure,
    }
}
