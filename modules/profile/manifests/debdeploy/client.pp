class profile::debdeploy::client (
    Array $exclude_mounts      = lookup('profile::debdeploy::client::exclude_mounts'),
    Array $exclude_filesystems = lookup('profile::debdeploy::client::exclude_filesystems'),
    Hash  $filter_services     = lookup('profile::debdeploy::client::filter_services')
) {
    class { 'debdeploy::client':
      exclude_mounts      => $exclude_mounts,
      exclude_filesystems => $exclude_filesystems,
      filter_services     => $filter_services,
    }
}
