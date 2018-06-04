# == Define: lvm::physical_volume
#
define lvm::physical_volume (
  $ensure     = present,
  $force      = false,
  $unless_vg  = undef,
) {

  if ($name == undef) {
    fail("lvm::physical_volume \$name can't be undefined")
  }

  physical_volume { $name:
    ensure    => $ensure,
    force     => $force,
    unless_vg => $unless_vg
  }

}
