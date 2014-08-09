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
#  apache::vars { 'apache_chuid':
#    vars => {
#      apache_run_user => 'apache',
#      apache_pid_file => '/var/run/apache2/apache2.pid',
#    },
#  }
#
define apache::env(
    $vars,
    $ensure   = present,
    $priority = 50,
) {
    include ::apache

    validate_hash($vars)

    apache::conf { $title:
        ensure    => $ensure,
        conf_type => 'env',
        content   => shell_exports($vars),
        priority  => $priority,
    }
}
