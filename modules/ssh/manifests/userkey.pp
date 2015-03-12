# == Define: ssh::userkey
#
# Manages an SSH user (authorized) key. Unlike the native ssh_authorized_keys
# type, it doesn't try to be smart about the arguments and only takes a
# $content or $source argument, allowing e.g. forced command configurations.
#
# Additionally, it does not try to coexist with preexisting, manual keys on the
# system. The key file is managed in its entirety; if multiple keys are needed,
# these need to be supplied in one go, in $content or $source, joined by
# newlines.
#
# === Parameters
#
# [*ensure*]
#   If 'present', config will be enabled; if 'absent', disabled.
#   The default is 'present'.
#
# [*content*]
#   If defined, will be used as the content of the configuration
#   file. Undefined by default. Mutually exclusive with 'source'.
#
# [*source*]
#   Path to file containing configuration directives. Undefined by
#   default. Mutually exclusive with 'content'.
#
# === Examples
#
#  ssh::userkey { 'john'
#    ensure => present,
#    source => 'puppet:///files/admin/ssh/john-rsa',
#  }
#

define ssh::userkey(
  $ensure  = present,
  $user    = $title,
  $source  = undef,
  $content = undef,

) {
    if $source == undef and $content == undef  {
        fail('you must provide either "source" or "content"')
    }

    if $source != undef and $content != undef  {
        fail('"source" and "content" are mutually exclusive')
    }

    file { "/etc/ssh/userkeys/${user}":
        ensure  => $ensure,
        force   => true,
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        content => $content,
        source  => $source,
    }
}
