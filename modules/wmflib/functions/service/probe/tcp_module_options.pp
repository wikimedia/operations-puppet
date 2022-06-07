# SPDX-License-Identifier: Apache-2.0

# Return the blackbox TCP module options for the given $service

# TODO support options for more than one probe if/when needed
function wmflib::service::probe::tcp_module_options(
  String $service_name,
  Wmflib::Service $service_config,
) >> Hash {
  if debian::codename::ge('bullseye') {
    $compat = { 'ip_protocol_fallback' => false }
  } else {
    $compat = {}
  }

  # Find out which SNI to send. Similar logic to
  # prometheus::service_catalog_targets for DNS names; in this case
  # try discovery since that is the standard going forward and
  # more likely for services to have it in SNI.

  # Offer users the option to override Host and SNI via probe 'host' field.
  if 'probes' in $service_config and 'host' in $service_config['probes'][0] {
    $tls_server_name = $service_config['probes'][0]['host']
  } elsif 'discovery' in $service_config {
    $disc_name = $service_config['discovery'][0]['dnsdisc']
    $tls_server_name = "${disc_name}.discovery.wmnet"
  } elsif 'aliases' in $service_config {
    $first_alias = $service_config['aliases'][0]
    $tls_server_name = "${first_alias}.svc.${::site}.wmnet"
  } else {
    $tls_server_name = "${service_name}.svc.${::site}.wmnet"
  }

  $tls_options = {
    'tls_config' => { 'server_name' => $tls_server_name },
    # Auto-detect TLS from service configuration, and force-disable
    # when tcp-notls is used.
    'tls'        => $service_config['probes'][0]['type'] ? {
                        'tcp-notls' => false,
                        default     => $service_config['encryption'],
                    }
  }

  return deep_merge($compat, $tls_options)
}
