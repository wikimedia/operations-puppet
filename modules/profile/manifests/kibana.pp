# == Class: profile::kibana
class profile::kibana (
  Boolean $enable_phatality = lookup('profile::kibana::enable_phatality', {'default_value' => true}),
  ) {
    class { 'kibana':
      enable_phatality => $enable_phatality,
    }
}
