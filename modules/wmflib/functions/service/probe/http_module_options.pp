# Return the blackbox HTTP module options for the given $service

# TODO support options for more than one probe if/when needed
function wmflib::service::probe::http_module_options(
  String $service_name,
  Wmflib::Service $service_config,
) >> Hash {
  if debian::codename::ge('bullseye') {
    $compat = { 'ip_protocol_fallback' => false }
  } else {
    $compat = {}
  }

  $probe = $service_config['probes'][0]

  if 'must_contain_regexp' in $probe {
    $key = debian::codename::ge('bullseye').bool2str(
      'fail_if_body_not_matches_regexp',
      'fail_if_not_matches_regexp'
    )
    $match = {
      $key => [ $probe['must_contain_regexp'] ],
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
    $host_header = {}
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

  return deep_merge($compat, $match, $post_json, $host_header, $valid_status_codes, $expect_sso)
}
