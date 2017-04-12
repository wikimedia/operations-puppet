# = Define: kmod::alias
#
# == Example
#
#     kmod::alias { 'bond0':
#       alias => 'bonding',
#     }
#
define kmod::alias(
  $source,
  $ensure     = 'present',
  $file       = "/etc/modprobe.d/${name}.conf",
  $aliasname  = $name,
) {

  include ::kmod

  kmod::setting { "kmod::alias ${title}":
    module   => $aliasname,
    file     => $file,
    category => 'alias',
    option   => 'modulename',
    value    => $source,
  }

}
