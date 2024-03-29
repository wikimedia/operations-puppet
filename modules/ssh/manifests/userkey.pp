# @summary
#   Manages an SSH user (authorized) key. Unlike the native ssh_authorized_keys
#   type, it doesn't try to be smart about the arguments and only takes a
#   $content or $source argument, allowing e.g. forced command configurations.
#
#   Additionally, it does not try to coexist with preexisting, manual keys on the
#   system. The key file is managed in its entirety; if multiple keys are needed,
#   these need to be supplied in one go, in $content or $source, joined by
#   newlines.
# @param ensure
#   If 'present', config will be enabled; if 'absent', disabled.
#   The default is 'present'.
# @param user
#   The user key to configure defaults to title
# @param content
#   If defined, will be used as the content of the configuration
#   file. Undefined by default. Mutually exclusive with 'source'.
# @param source
#   Path to file containing configuration directives. Undefined by
#   default. Mutually exclusive with 'content'.
# @param skey
#   If defined, a supplemental key for a user will be defined. The key will be
#   stored in a file named ${user}.d/skey. ${user.d} will be created as well if
#   it is not already defined. You probably don't want to use this for most
#   cases.
#
# @example Examples
#
#  ssh::userkey { 'john'
#    ensure => present,
#    source => 'puppet:///files/admin/ssh/john-rsa',
#  }
#
define ssh::userkey(
  Wmflib::Ensure               $ensure  = present,
  String[1]                    $user    = $title,
  Optional[String[1]]          $skey    = undef,
  Optional[Stdlib::Filesource] $source  = undef,
  Optional[String[1]]          $content = undef,

) {
    if $skey {
        if !defined(File["/etc/ssh/userkeys/${user}.d/"]) {
            file { "/etc/ssh/userkeys/${user}.d/":
                ensure => directory,
                force  => true,
                owner  => 'root',
                group  => 'root',
                mode   => '0755',
            }
        }
        $path = "/etc/ssh/userkeys/${user}.d/${skey}"
    } else {
        $path = "/etc/ssh/userkeys/${user}"
    }

    file { $path:
        ensure    => stdlib::ensure($ensure, 'file'),
        force     => true,
        owner     => 'root',
        group     => 'root',
        mode      => '0444', # sshd drops perms before trying to read public keys
        content   => $content,
        source    => $source,
        show_diff => false,
    }
}
