class profile::toolforge::services::basic(
    $active_node = hiera('profile::toolforge::services::active_node'),
  ) {
    diamond::collector { 'SGE':
        source   => 'puppet:///modules/toollabs/monitoring/sge.py',
    }
}
