# SPDX-License-Identifier: Apache-2.0
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
# [*service_ensure*]
#    The usual parameter to ensure the service is stopped or running. Default: running
define testreduce::server(
    String $instance_name,
    String $db_name,
    String $db_user,
    String $db_pass,
    Stdlib::Unixpath $db_socket,
    Stdlib::Fqdn $db_host = 'localhost',
    Stdlib::Port $db_port = 3306,
    Stdlib::Port $coord_port = 8002,
    Stdlib::Port $webapp_port = 8003,
    Stdlib::Ensure::Service $service_ensure = 'running',
) {
    file { "/etc/testreduce/${instance_name}.settings.js":
        # FIXME: Ideally this would be testreduce/settings.js.rb
        # but, I need to parameterize it a bit more.
        # So, this is a bit lame right now.
        content => template("testreduce/${instance_name}.settings.js.erb"),
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
        notify => Service[$instance_name],
    }

    service { $instance_name:
        ensure  => $service_ensure,
        require => [
            File["/etc/testreduce/${instance_name}.settings.js"],
            File["/lib/systemd/system/${instance_name}.service"],
        ],
    }
}
