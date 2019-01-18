class profile::toolforge::services::basic(
    $active_node = hiera('profile::toolforge::services::active_node'),
  ) {
    diamond::collector { 'SGE':
        ensure => 'absent',
    }
}
