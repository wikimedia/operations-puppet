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
# [*skey*]
#   If defined, a supplemental key for a user will be defined. The key will be
#   stored in a file named ${user}.d/skey. ${user.d} will be created as well if
#   it is not already defined. You probably don't want to use this for most
#   cases.
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
  $skey    = $title,
  $source  = undef,
  $content = undef,
) {
    $userkeys = "/etc/ssh/userkeys/${user}"
    $userkeys_d = "/etc/ssh/userkeys/${user}.d"
    $thiskey = "${userkeys_d}/${skey}"

    if !defined(File[$userkeys_d]) {
        file { $userkeys_d:
            ensure => directory,
            force  => true,
            owner  => 'root',
            group  => 'root',
            mode   => '0755',
        }
    }

    # Compile /etc/ssh/userkeys/${user} from individual keys in
    # /etc/ssh/userkeys/${user}.d/
    if !defined(Exec["compile_ssh_userkeys_${user}"]) {
        exec { "compile_ssh_userkeys_${user}":
            path    => '/usr/bin:/bin',
            command => "/usr/bin/awk 'FNR==1{print}' ${userkeys_d}/* > ${userkeys}",
            creates => $userkeys,
            user    => $user,
        }

        file { $userkeys:
            ensure  => 'file',
            owner   => $user,
            mode    => '0644',
            require => Exec["compile_ssh_userkeys_${user}"],
        }
    }

    file { $thiskey:
        ensure  => $ensure,
        force   => true,
        owner   => 'root',
        group   => 'root',
        mode    => '0444', # sshd drops perms before trying to read public keys
        content => $content,
        source  => $source,
        notify  => Exec["compile_ssh_userkeys_${user}"],
    }

}
