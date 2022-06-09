# SPDX-License-Identifier: Apache-2.0
# @summary internal resource to manage an envoy file on disk
#
# @api private
define envoyproxy::conf(
  String $content,
  Enum['listener', 'cluster'] $conf_type,
  Integer[0,99] $priority = 50,
) {
  $safe_title = regsubst($title, '\W', '_', 'G')
  # First of all, we can't configure anything if envoy is not installed.
  if !defined(Class['envoyproxy']) {
    fail('This resource should only be used once the envoyproxy class is declared.')
  }
  $priority_string = sprintf('%02d', $priority)

  # Please note we don't use validate_cmd here because we want to avoid
  # race conditions where a listener gets applied before the corresponding
  # clusters are applied, thus failing verification.
  #
  # While the wrong file will be written to disk, we are guaranteed that:
  # - it will never be composed into the actual configuration file until it produces
  #   a valid configuration
  # - We will be notified of the failure
  file { "${envoyproxy::envoy_directory}/${conf_type}s.d/${priority_string}-${safe_title}.yaml":
    ensure  => present,
    content => $content,
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    notify  => Exec['verify-envoy-config']
  }
}
