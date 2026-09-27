## Release 1.2.0
### Summary
This release is a roll up of minor bugfixes.

### Added
- The upper bound for the stdlib dependency has been increased to 6.0.0
- The module mount_core has been added as a dependency after having been removed from the puppet core.
- Support added for Puppet 5 and 6.

### Bugfixes
- Test code left over from previous work has been removed.
- Fix added so that attempts are no longer made to run lvm commands when they are not supported.
- Rubygem version pinned on travis when ruby version less than 2.3.0.

## Release 1.1.0
### Summary
This is a feature release in order to add facts, functions, tasks and plans alongside some smaller bugfixes and additions.

### Added
- Functions added for onverting to and from bytes.
- Tasks added for common actions that use types and providors.
- Plan for one touch expanding, expanded.
- Support has been added for LVM thin volumes.
- Facts have been structured.
- Provider modified to allow `puppet resource` to work with `logical_volumes`.
- LVM providers have been confined to linux.

### Bugfixes
- Redundant code removed from facts.
- Fixed issues that were causing compilation to fail in tests.

## Release 1.0.1
### Summary
This release is a roll up of minor bugfixes.

### Fixed
- Don't execute the lvm commands when not supported.
- Fix error when creating XFS on top of another Filesystem.
- Type `Hash` added as acceptable type for physical_volumes.

## Release 1.0.0
### Summary
This release is a roll up of bug fixes and minor features. It also includes the introduction of Puppet 4 daya types. This release was prompted by the following issue: ([MODULES-4067](https://tickets.puppet.com/browse/MODULES-4067))

### Added
- `createonly` option for the volumegroup
- 30s Timeout for lvm support
- `followsymlinks` parameter
- Archlinux entry to 'metadata.json'
- Puppet 4 data types
- 'swapon' command to filesystem provider ([MODULES-4753](https://tickets.puppet.com/browse/MODULES-4753))
- Allow removal of swap LVMs ([MODULES-4753](https://tickets.puppet.com/browse/MODULES-4753))
- Logic preventing a mount on fs_type swap ([MODULES-4753](https://tickets.puppet.com/browse/MODULES-4753))
- Gracefully handle blkid return code 2 ([MODULES-4067](https://tickets.puppet.com/browse/MODULES-4067))

### Changed
- Set default mount option for dump to 0
- Better regexp for parsing the output of lvs
- Facter::Util::Resolution to Facter::Core::Execution
- `thinpool` parameter default to `false`
- stdlib requirement to >= 4.13.1
- Puppet minial version requirement to >= 4.6.1
- Provider and tests ([MODULES-4753](https://tickets.puppet.com/browse/MODULES-4753))

### Removed
- 'extent size' check in logical_volume provider
- redundant swap exec resources ([MODULES-4753](https://tickets.puppet.com/browse/MODULES-4753))

## Release 0.9.0
### Summary
Small release that bumps up rspec version and adds a new parameter

### Features
- Adds `followsymlinks` parameter

## Release 0.8.0
### Summary
This release includes more testing, support for ruby 2.3.1, thin provisioning and manage mirrors.

### Features
- Lots of test maintenance, tests updated and improved
- Add flag to Logical_volume to not resize filesystem
- Add support for thin provisioning and setting poolmetadatasize

### Bugfixes
- Add missing parameters to manage mirrors for lvm::logical_volume
- Executed command `swapoff` before unmount swap partion
- Fix parsing size from lvs output
- Numerous documentation fixes

## Release 0.7.0
### Features
- Add a flag `mounted` to tell puppet not to mount a volume itself.

### Bugfixes
- #139: fix errors under strict_variables with `manage_pkg`.

## Release 0.6.0
### Summary
This release includes support for new parameters, lots of unit tests, and tweaks to make sure everything works on different versions of puppet and lvm

#### Features
- Update .travis.yml to run puppet 3.0 and higher
- Add swap support
- Add RAL to types
- List all PVs in a VG
- Unit tests for types
- Adds `type` parameter for logical volume creation
- Adds support to the resize of a logical volume with swap

#### Bugfixes
- Filesystem type can create journal devices
- Add persistent and minor parameters to logical volume type
- Make size_is_minsize usable
- Add support for older lvm versions
- Fixes an error in `pvcreate` produced when `force => false`

## 2015-04-28 - Release 0.5.0
### Summary

This release contains new parameters, a number of bugfixes, and improved tests.

#### Features
- New parameters in `lvm::logical_volume`
  - `$readahead`
  - `$pass`
  - `$dump`
- Mirror support
- Ordering of resource creation
- Allow creation of LV without a filesystem or mount points

#### Bugfixes
- Correctly escape dashes in LVM name
- Updates $ensure checking to be puppet4 compliant.
- Fixes filesystem detection bug
- Correctly escape dashes in VG names (MODULES-1801)
- Validates logical_volume name is not undef

## 2014-12-2 - Release 0.4.0
### Summary

This release contains a number of new parameters, adds support for non-integer sizes, and has a number of bugfixes.

#### Features
- New parameters in `lvm::logical_volume`
  - `$initial_size`
  - `$mkfs_options`
  - `$stripes`
  - `$extents`
  - `$stripesize`
  - `$range`
- New `size_is_minsize` parameter in `logical_volume` type
- Allow non-integer sizes

#### Bugfixes
- Lint fixes
- Fixed volume_group to be sorted upon comparision
- Consider `fs_type` in `exists?` function
- Metadata fixes

## 2014-09-16 - Release 0.3.3
### Summary

This release fixes an issue with the metadata and fixes a bug with
initial_size.

#### Bugfixes
- Remove Modulefile and move dependencies to metadata.json
- Don't set --extents=100%FREE if initial_size is set

## 2014-06-25 - Release 0.3.2
### Summary

This release fixes a couple of small, but important, bugs.

#### Bugfixes
- Fix the size comparision to be unit aware.
- Fix exec that was missing a path attribute.
- Add autorequire for the volume_group.

## 2014-04-11 - Release 0.3.1
### Summary

This release simply adds metadata consumed by the forge for displaying
operating system compatibility.  No other changes.

## 2014-04-10 - Release 0.3.0
### Summary

This release features a new base lvm class, and set of defines, that allows you
to express your volume groups through a `volume_groups` parameter.  This makes
it easier to hiera backend your LVM configuration.

More information about this feature can be found in the README file.

## 2014-02-04 - Release 0.2.0
### Summary

It's been a long time since the previous release and the LVM module has seen a
lot of community development.  It now supports AIX, thanks to Craig Dunn, and
grew an enormous number of facts, properties, and parameters.  There's a
fistful of bugfixes too which should help RHEL5 users.

#### Features
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

#### Bugfixes
- Fix messages with new_size variables in logical_volume/lvm.rb
- size 'undef' doesn't work when creating a new logical volume
- resize2fs isn't called during resizing on ruby>1.
- Allow for physical_volumes and volume_groups that change as system lives.
- On RHEL 5 family systems ext4 filesystems can not be resized using resize2fs.
- Suppress facter warnings on systems that don't support LVM.
