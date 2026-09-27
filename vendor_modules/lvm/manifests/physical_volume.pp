# @summary Manage a physical volume
#
# @param ensure ensures phycial volume is present or absent
#
# @param force Whether to force the creation without any confirmation.
#
# @param unless_vg Do not do anything if the VG already exists. The value should be the name of the volume group to check for.
#
define lvm::physical_volume (
  Enum['present', 'absent'] $ensure = present,
  Boolean $force                    = false,
  Optional[String[1]] $unless_vg    = undef,
) {
  if ($name == undef) {
    fail("lvm::physical_volume \$name can't be undefined")
  }

  physical_volume { $name:
    ensure    => $ensure,
    force     => $force,
    unless_vg => $unless_vg,
  }
}
