# SPDX-License-Identifier: Apache-2.0
# == Define: apache::env
#
# This resource provides an easy way to declare environment variables
# for Apache.
#
# === Parameters
#
# [*ensure*]
#   If 'present', the environment variables will be defined; if absent,
#   undefined. The default is 'present'.
#
# [*vars*]
#   A hash which maps variable names to values. Keys are uppercased.
#
# [*priority*]
#   If you need these vars defined before or after other scripts, you
#   can do so by manipulating this value. In most cases, the default
#   value of 50 should be fine.
#
# === Example
#
#  apache::env { 'apache_chuid':
#    vars => {
#      apache_run_user => 'www-data',
#      apache_pid_file => '/var/run/apache2/apache2.pid',
#    },
#  }
#
define httpd::env(
    Hash[String,String] $vars,
    Wmflib::Ensure $ensure   = present,
    Integer[0,99] $priority = 50,
) {
    httpd::conf { $title:
        ensure    => $ensure,
        conf_type => 'env',
        content   => template('httpd/env.conf.erb'),
        priority  => $priority,
    }
}
