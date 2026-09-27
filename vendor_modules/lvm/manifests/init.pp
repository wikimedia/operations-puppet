# @summary Manage LVM
#
# @param package_ensure
#   Ensure value for the lvm2 package.
#
# @param manage_pkg
#   Whether to manage the lvm2 package.
#
# @param volume_groups
#   Hash of lvm::volume_group resources to create.
#
class lvm (
  Enum['installed', 'present', 'latest', 'absent'] $package_ensure = 'installed',
  Boolean $manage_pkg                                              = false,
  Hash $volume_groups                                              = {},
) {
  if $manage_pkg {
    package { 'lvm2':
      ensure => $package_ensure,
    }
  }

  create_resources('lvm::volume_group', $volume_groups)
}
