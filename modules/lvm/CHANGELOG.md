##Release 0.7.0
###Features
- Add a flag `mounted` to tell puppet not to mount a volume itself.

###Bugfixes
- #139: fix errors under strict_variables with `manage_pkg`.

##Release 0.6.0
###Summary
This release includes support for new parameters, lots of unit tests, and tweaks to make sure everything works on different versions of puppet and lvm

####Features
- Update .travis.yml to run puppet 3.0 and higher
- Add swap support
- Add RAL to types
- List all PVs in a VG
- Unit tests for types
- Adds `type` parameter for logical volume creation
- Adds support to the resize of a logical volume with swap

####Bugfixes
- Filesystem type can create journal devices
- Add persistent and minor parameters to logical volume type
- Make size_is_minsize usable
- Add support for older lvm versions
- Fixes an error in `pvcreate` produced when `force => false`

##2015-04-28 - Release 0.5.0
###Summary

This release contains new parameters, a number of bugfixes, and improved tests.

####Features
- New parameters in `lvm::logical_volume`
  - `$readahead`
  - `$pass`
  - `$dump`
- Mirror support
- Ordering of resource creation
- Allow creation of LV without a filesystem or mount points

####Bugfixes
- Correctly escape dashes in LVM name
- Updates $ensure checking to be puppet4 compliant.
- Fixes filesystem detection bug
- Correctly escape dashes in VG names (MODULES-1801)
- Validates logical_volume name is not undef

##2014-12-2 - Release 0.4.0
###Summary

This release contains a number of new parameters, adds support for non-integer sizes, and has a number of bugfixes.

####Features
- New parameters in `lvm::logical_volume`
  - `$initial_size`
  - `$mkfs_options`
  - `$stripes`
  - `$extents`
  - `$stripesize`
  - `$range`
- New `size_is_minsize` parameter in `logical_volume` type
- Allow non-integer sizes

####Bugfixes
- Lint fixes
- Fixed volume_group to be sorted upon comparision
- Consider `fs_type` in `exists?` function
- Metadata fixes

##2014-09-16 - Release 0.3.3
###Summary

This release fixes an issue with the metadata and fixes a bug with
initial_size.

####Bugfixes
- Remove Modulefile and move dependencies to metadata.json
- Don't set --extents=100%FREE if initial_size is set

##2014-06-25 - Release 0.3.2
###Summary

This release fixes a couple of small, but important, bugs.

####Bugfixes
- Fix the size comparision to be unit aware.
- Fix exec that was missing a path attribute.
- Add autorequire for the volume_group.

##2014-04-11 - Release 0.3.1
###Summary

This release simply adds metadata consumed by the forge for displaying
operating system compatibility.  No other changes.

##2014-04-10 - Release 0.3.0
###Summary

This release features a new base lvm class, and set of defines, that allows you
to express your volume groups through a `volume_groups` parameter.  This makes
it easier to hiera backend your LVM configuration.

More information about this feature can be found in the README file.

##2014-02-04 - Release 0.2.0
###Summary

It's been a long time since the previous release and the LVM module has seen a
lot of community development.  It now supports AIX, thanks to Craig Dunn, and
grew an enormous number of facts, properties, and parameters.  There's a
fistful of bugfixes too which should help RHEL5 users.

####Features
 - A new `lvm_support` fact was added. 
 - A new `lvm_vgs` fact was added.
 - A new `lvm_pvs` fact was added.
 - Dynamic facts were added for lvm_vg_N and lvm_pv_N.
 - Support for lvcreate -l argument (extents)
 - Added AIX providers for logical_volume and filesystem types.
 - Use ensure_resources to handle multiple physical_volume in a volume_group.
 - Add XFS online resizing support.
 - Add `initial_size` property.
 - Add `extents` property.
 - Add `stripes` property.
 - Add `stripsize` property.
 - Huge number of parameters were added, most AIX only.

####Bugfixes
- Fix messages with new_size variables in logical_volume/lvm.rb
- size 'undef' doesn't work when creating a new logical volume
- resize2fs isn't called during resizing on ruby>1.
- Allow for physical_volumes and volume_groups that change as system lives.
- On RHEL 5 family systems ext4 filesystems can not be resized using resize2fs.
- Suppress facter warnings on systems that don't support LVM.
