# == Class: lvm
#
class lvm (
  $package_ensure = 'installed',
  $manage_pkg     = undef,
  $volume_groups  = {},
) {

  if $manage_pkg {
    package { 'lvm2':
      ensure   => $package_ensure
    }
  }

  validate_hash($volume_groups)

  create_resources('lvm::volume_group', $volume_groups)
}
