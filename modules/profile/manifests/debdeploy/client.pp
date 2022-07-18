# SPDX-License-Identifier: Apache-2.0
class profile::debdeploy::client (
    Wmflib::Ensure $ensure              = lookup('profile::debdeploy::client::ensure'),
    Array          $exclude_mounts      = lookup('profile::debdeploy::client::exclude_mounts'),
    Array          $exclude_filesystems = lookup('profile::debdeploy::client::exclude_filesystems'),
    Hash           $filter_services     = lookup('profile::debdeploy::client::filter_services')
) {
    class { 'debdeploy::client':
        ensure              => $ensure,
        exclude_mounts      => $exclude_mounts,
        exclude_filesystems => $exclude_filesystems,
        filter_services     => $filter_services,
    }
}
