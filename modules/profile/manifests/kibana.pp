# == Class: profile::kibana
class profile::kibana (
  Enum['5', '6', '7'] $config_version   = lookup('profile::kibana::config_version',     {'default_value' => '7'}),
  Boolean $enable_phatality             = lookup('profile::kibana::enable_phatality',   {'default_value' => true}),
  String $package_name                  = lookup('profile::kibana::package_name',       {'default_value' => 'kibana'}),
  Optional[Boolean] $tile_map_enabled   = lookup('profile::kibana::tile_map_enabled',   {'default_value' => undef}),
  Optional[Boolean] $region_map_enabled = lookup('profile::kibana::region_map_enabled', {'default_value' => undef}),
  Optional[String]  $kibana_index       = lookup('profile::kibana::kibana_index',       {'default_value' => undef}),
  Optional[Boolean] $enable_warnings    = lookup('profile::kibana::enable_warnings',    {'default_value' => undef}),
  ) {
    class { 'kibana':
      config_version     => $config_version,
      kibana_package     => $package_name,
      enable_phatality   => $enable_phatality,
      tile_map_enabled   => $tile_map_enabled,
      region_map_enabled => $region_map_enabled,
      kibana_index       => $kibana_index,
      enable_warnings    => $enable_warnings,
    }
}
