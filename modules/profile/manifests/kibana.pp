# == Class: profile::kibana
class profile::kibana (
  Boolean $enable_phatality = lookup('profile::kibana::enable_phatality', {'default_value' => true}),
  String $package_name      = lookup('profile::kibana::package_name', {'default_value' => 'kibana'})
  ) {
    class { 'kibana':
      enable_phatality => $enable_phatality,
      kibana_package   => $package_name,
    }
}
