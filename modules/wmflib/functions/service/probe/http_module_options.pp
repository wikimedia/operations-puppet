# SPDX-License-Identifier: Apache-2.0

# Return the blackbox HTTP module options for the given $service

# TODO support options for more than one probe if/when needed
function wmflib::service::probe::http_module_options(
  String $service_name,
  Wmflib::Service $service_config,
) >> Hash {
  $common = { 'ip_protocol_fallback' => false }

  # Find out which SNI to send. Similar logic to
  # prometheus::targets::service_catalog for DNS names; in this case
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
    'fail_if_ssl'     => !$service_config['encryption'],
    'fail_if_not_ssl' => $service_config['encryption'],
    'tls_config'      => { 'server_name' => $tls_server_name },
  }

  if 'probes' in $service_config {
    $probe = $service_config['probes'][0]
  } else {
    $probe = {}
  }

  if 'must_contain_regexp' in $probe {
    $match = {
      'fail_if_body_not_matches_regexp' => [ $probe['must_contain_regexp'] ],
    }
  } else {
    $match = {}
  }

  if 'post_json' in $probe {
    $post_json = {
      'method'  => 'POST',
      'body'    => $probe['post_json'],
      'headers' => {
        'Content-Type' => 'application/json',
      },
    }
  } else {
    $post_json = {}
  }

  if 'host' in $probe {
    $host_header = {
      'headers' => {
        'Host' => $probe['host'],
      },
    }
  } else {
    $host_header = {
      'headers' => {
        'Host' => $tls_server_name,
      },
    }
  }

  if 'valid_status_codes' in $probe {
    $valid_status_codes = {
      'valid_status_codes' => $probe['valid_status_codes'],
    }
  } else {
    $valid_status_codes = {}
  }

  if 'expect_sso' in $probe {
    $expect_sso = {
      'valid_status_codes'  => [ 302 ],
      'no_follow_redirects' => true,
    }
  } else {
    $expect_sso = {}
  }

  if 'expect_redirect' in $probe {
    $expect_redirect = {
      'valid_status_codes'  => [ 301, 302 ],
      'no_follow_redirects' => true,
    }
  } else {
    $expect_redirect = {}
  }

  return deep_merge($common, $match, $post_json, $host_header,
    $valid_status_codes, $expect_sso, $expect_redirect, $tls_options)
}
