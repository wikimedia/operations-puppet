# == Define: lvm::volume
#
# This defined type will create a <code>logical_volume</code> with the name of
# the define and ensure a <code>physical_volume</code>,
# <code>volume_group</code>, and <code>filesystem</code> resource have been
# created on the block device supplied.
#
# === Parameters
#
# [*ensure*] Can only be set to <code>cleaned</code>, <code>absent</code> or
# <code>present</code>. A value of <code>present</code> will ensure that the
# <code>physical_volume</code>, <code>volume_group</code>,
# <code>logical_volume</code>, and <code>filesystem</code> resources are
# present for the volume. A value of <code>cleaned</code> will ensure that all
# of the resources are <code>absent</code> <b>Warning this has a high potential
# for unexpected harm</b> use it with caution. A value of <code>absent</code>
# will remove only the <code>logical_volume</code> resource from the system.
# [*pv*] The block device to ensure a <code>physical_volume</code> has been
# created on.  [*vg*] The <code>volume_group</code> to ensure is created on the
# <code>physical_volume</code> provided by the <code>pv</code> parameter.
# [*fstype*] The type of <code>filesystem</code> to create on the logical
# volume.  [*size*] The size the <code>logical_voluem</code> should be.
#
# === Examples
#
# Provide some examples on how to use this type:
#
#   lvm::volume { 'lv_example0':
#     vg     => 'vg_example0',
#     pv     => '/dev/sdd1',
#     fstype => 'ext4',
#     size => '100GB',
#   }
#
# === Copyright
#
# See README.markdown for the module author information.
#
# === License
#
# This file is part of the puppetlabs/lvm puppet module.
#
# puppetlabs/lvm is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation, version 2 of the License.
#
# puppetlabs/lvm is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with puppetlabs/lvm. If not, see http://www.gnu.org/licenses/.
#
define lvm::volume (
  $ensure,
  $pv,
  $vg,
  $fstype  = undef,
  $size    = undef,
  $extents = undef,
  $initial_size = undef
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
          before           => Physical_volume[$pv]
        }

        logical_volume { $name:
          ensure       => present,
          volume_group => $vg,
          size         => $size,
          initial_size => $initial_size,
          before       => Volume_group[$vg]
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
        size         => $size
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
          require          => Physical_volume[$pv]
        }
      }

      logical_volume { $name:
        ensure       => present,
        volume_group => $vg,
        size         => $size,
        extents      => $extents,
        require      => Volume_group[$vg]
      }

      if $fstype != undef {
        filesystem { "/dev/${vg}/${name}":
          ensure  => present,
          fs_type => $fstype,
          require => Logical_volume[$name]
        }
      }

    }
    default: {
      fail ( 'puppet-lvm::volume: ensure parameter can only be set to ' +
        'cleaned, absent or present' )
    }
  }
}
