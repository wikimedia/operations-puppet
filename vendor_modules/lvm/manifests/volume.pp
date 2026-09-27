# @summary Manage a logical_volume.
# Ensures a physical_volume, volume_group, and filesystem resource
# have been created on the block device supplied in the pv parameter.
#
# @param ensure Can only be set to cleaned, absent or present. A value of present will ensure that the
# physical_volume, volume_group,
# logical_volume, and filesystem resources are
# present for the volume. A value of cleaned will ensure that all
# of the resources are absent. Warning: this has a high potential
# for unexpected harm, so use it with caution. A value of absent
# will remove only the logical_volume resource from the system.
#
# @param fstype The type of filesystem to create on the logical
# volume.
#
# @param pv path to physcial volume
#
# @param vg value of volume group
#
# @param size The size the logical_voluem should be.
#
# @param extents The number of logical extents to allocate for the new logical volume.
# Set to undef to use all available space
#
# @param initial_size The initial size of the logical volume.
# This will only apply to newly-created volumes
#
# @example Basic usage
#
#   lvm::volume { 'lv_example0':
#     vg     => 'vg_example0',
#     pv     => '/dev/sdd1',
#     fstype => 'ext4',
#     size   => '100GB',
#   }
#
define lvm::volume (
  Enum['present', 'absent', 'cleaned'] $ensure,
  Stdlib::Absolutepath $pv,
  String[1] $vg,
  Optional[String[1]] $fstype                     = undef,
  Optional[String[1]] $size                       = undef,
  Optional[Variant[String[1], Integer]] $extents  = undef,
  Optional[String[1]] $initial_size               = undef
) {
  if ($name == undef) {
    fail("lvm::volume \$name can't be undefined")
  }

  case $ensure {
    #
    # Clean up the whole chain.
    #
    'cleaned': {
      # This may only need to exist once
      if ! defined(Physical_volume[$pv]) {
        physical_volume { $pv: ensure => present }
      }
      # This may only need to exist once
      if ! defined(Volume_group[$vg]) {
        volume_group { $vg:
          ensure           => present,
          physical_volumes => $pv,
          before           => Physical_volume[$pv],
        }

        logical_volume { $name:
          ensure       => present,
          volume_group => $vg,
          size         => $size,
          initial_size => $initial_size,
          before       => Volume_group[$vg],
        }
      }
    }
    #
    # Just clean up the logical volume
    #
    'absent': {
      logical_volume { $name:
        ensure       => absent,
        volume_group => $vg,
        size         => $size,
      }
    }
    #
    # Create the whole chain.
    #
    'present': {
      # This may only need to exist once.  Requires stdlib 4.1 to
      # handle $pv as an array.
      ensure_resource('physical_volume', $pv, { 'ensure' => $ensure })

      # This may only need to exist once
      if ! defined(Volume_group[$vg]) {
        volume_group { $vg:
          ensure           => present,
          physical_volumes => $pv,
          require          => Physical_volume[$pv],
        }
      }

      logical_volume { $name:
        ensure       => present,
        volume_group => $vg,
        size         => $size,
        extents      => $extents,
        require      => Volume_group[$vg],
      }

      if $fstype != undef {
        filesystem { "/dev/${vg}/${name}":
          ensure  => present,
          fs_type => $fstype,
          require => Logical_volume[$name],
        }
      }
    }
    default: {
      fail ( sprintf('%s%s', 'puppet-lvm::volume: ensure parameter can only ',
      'be set to cleaned, absent or present') )
    }
  }
}
