# @summary imports blackbox checks from puppetdb
# SPDX-License-Identifier: Apache-2.0
define prometheus::blackbox::import_checks (
  String        $prometheus_instance,
  Wmflib::Sites $site,
) {
  # Legacy path, remove this file definition eventually
  file { "/srv/prometheus/${prometheus_instance}/targets/probes-custom_puppet.yaml":
    ensure => absent,
  }

  ['http', 'tcp'].each |String $module| {
    wmflib::resource::import(
      'prometheus::blackbox::module',
      undef,
      { tag => "prometheus::blackbox::check::${module}::${site}::${prometheus_instance}::module" }
    )

    wmflib::resource::import(
      'prometheus::rule',
      undef,
      { tag => "prometheus::blackbox::check::${module}::${::site}::${prometheus_instance}::alert" }
    )

    # TODO: the following will concatenate all content simlar to the puppetlabs::concat module
    # We need to check if we need to inser addtional line breaks (\n)
    # also if we want to do something similar for alert files?
    wmflib::resource::import(
      'file',
      undef,
      { tag => "prometheus::blackbox::check::${module}::${::site}::${prometheus_instance}::target" },
      true
    )
  }
}
