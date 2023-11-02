# SPDX-License-Identifier: Apache-2.0
# @summary applies a patch to the openstack source files
# @param source Patch file source
# @param file Filesystem path of the file to patch
define openstack::patch (
  Stdlib::Filesource $source,
  Stdlib::Unixpath   $file   = $title,
) {
  ensure_packages(['patch'])

  $patch_file = "${file}.patch"
  file { $patch_file:
    ensure => file,
    source => $source,
    owner  => 'root',
    group  => 'root',
    mode   => '0444',
  }

  exec { "apply ${patch_file}":
    command => "/usr/bin/patch --forward ${file} ${patch_file}",
    unless  => "/usr/bin/patch --reverse --dry-run -f ${file} ${patch_file}",
    require => [File[$patch_file], Package['patch']],
  }
}
