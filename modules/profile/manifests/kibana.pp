# == Class: profile::kibana
class profile::kibana (
  Boolean $enable_phatality = lookup('profile::kibana::enable_phatality', {'default_value' => true}),
  String $package_name      = lookup('profile::kibana::package_name', {'default_value' => 'kibana'}),
  Optional[Boolean] $tile_map_enabled   = lookup('profile::kibana::tile_map_enabled', {'default_value' => undef}),
  Optional[Boolean] $region_map_enabled = lookup('profile::kibana::region_map_enabled', {'default_value' => undef}),
  ) {
    class { 'kibana':
      kibana_package     => $package_name,
      enable_phatality   => $enable_phatality,
      tile_map_enabled   => $tile_map_enabled,
      region_map_enabled => $region_map_enabled,
    }
}
