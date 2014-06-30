# == Define: apache::envvar
#
# This resource provides an easy way to declare a runtime parameter
# for Apache. It can then be used in Apache <IfDefine> checks.
#
# === Parameters
#
# [*ensure*]
#   If 'present', the environment variable will be defined; if absent, undefined.
#   The default is 'present'.
#
# === Example
#
#  apache::envvar { 'HHVM':
#    ensure => present,
#  }
#
define apache::envvar( $ensure = present ) {
    include ::apache
    include stdlib

    file_line { "apache2_param_${title}":
        ensure => $ensure,
        path   => '/etc/apache2/envvars',
        line   => "export APACHE_ARGUMENTS=\"\$APACHE_ARGUMENTS -D ${title}\"",
        notify => Service['apache2']
    }
}
