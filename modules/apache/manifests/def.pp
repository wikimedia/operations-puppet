# == Define: apache::def
#
# This resource provides an easy way to declare a runtime parameter
# for Apache. It can then be used in Apache <IfDefine> checks.
#
# === Parameters
#
# [*ensure*]
#   If 'present', the environment variable will be defined; if absent,
#   undefined. The default is 'present'.
#
# [*priority*]
#   If you need this var defined before or after other scripts, you can
#   do so by manipulating this value. In most cases, the default value
#   of 50 should be fine.
#
# === Example
#
#  apache::def { 'HHVM':
#    ensure => present,
#  }
#
define apache::def(
    $ensure   = present,
    $priority = 50,

) {
    include ::apache
    include ::stdlib

    apache::conf { "define_${title}":
        ensure    => $ensure,
        conf_type => 'env',
        priority  => $priority,
        content   => $content,
        source    => $source,
    }
}
