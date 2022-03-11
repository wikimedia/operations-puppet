# == Class: lvm
#
class lvm (
  Enum['installed', 'present', 'latest', 'absent'] $package_ensure = 'installed',
  Boolean $manage_pkg                                              = false,
  Hash $volume_groups                                              = {},
) {

  if $manage_pkg {
    package { 'lvm2':
      ensure   => $package_ensure
    }
  }

  create_resources('lvm::volume_group', $volume_groups)
}
