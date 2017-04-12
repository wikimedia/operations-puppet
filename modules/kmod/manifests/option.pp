# = Define: kmod::alias
#
# == Example
#
#     kmod::option { 'bond0':
#       option => 'bonding',
#     }
#
define kmod::option(
  $option,
  $value,
  $module = $name,
  $ensure = 'present',
  $file   = undef,
) {

  include ::kmod

  $target_file = $file ? {
    undef   => "/etc/modprobe.d/${module}.conf",
    default => $file,
  }


  kmod::setting { "kmod::option ${title}":
    ensure   => $ensure,
    module   => $module,
    category => 'options',
    file     => $target_file,
    option   => $option,
    value    => $value,
  }

}

