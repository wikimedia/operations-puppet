# @summary Manage a volume group.
#
# @param physical_volumes
#   The list of physical volumes to be included in the volume group.
#   This will automatically set these as dependencies, but they must
#   be defined elsewhere using the physical_volume resource type.
#
# @param createonly
#   If true, the volume group will be created if it does not exist. If
#   the volume group does exist, no action will be taken.
#
# @param ensure
#   Whether this volume group should be present or absent.
#
# @param logical_volumes
#   A hash of lvm::logical_volume resources to create in this volume
#   group.
#
# @param followsymlinks
#   If true, all current and wanted values of the physical_volumes
#   property will be followed to their real files on disk if they are
#   in fact symlinks. This is useful to have Puppet determine what the
#   actual PV device is if the property value is a symlink, like
#   `/dev/disk/by-path/xxxx -> ../../sda`.
#
define lvm::volume_group (
  Variant[Hash, Array, String] $physical_volumes,
  Boolean $createonly               = false,
  Enum['present', 'absent'] $ensure = present,
  Hash $logical_volumes             = {},
  Boolean $followsymlinks           = false,
) {
  if $physical_volumes.is_a(Hash) {
    create_resources(
      'lvm::physical_volume',
      $physical_volumes,
      {
        ensure           => $ensure,
      }
    )
  }
  else {
    physical_volume { $physical_volumes:
      ensure => $ensure,
    }
  }

  volume_group { $name:
    ensure           => $ensure,
    createonly       => $createonly,
    physical_volumes => $physical_volumes,
    followsymlinks   => $followsymlinks,
  }

  create_resources(
    'lvm::logical_volume',
    $logical_volumes,
    {
      ensure       => $ensure,
      volume_group => $name,
    }
  )
}
