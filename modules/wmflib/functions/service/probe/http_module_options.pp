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

  if 'must_contain_regexp' in $service_config['probes'][0] {
    $key = debian::codename::ge('bullseye').bool2str(
      'fail_if_body_not_matches_regexp',
      'fail_if_not_matches_regexp'
    )
    $match = {
      $key => [ $service_config['probes'][0]['must_contain_regexp'] ],
    }
  } else {
    $match = {}
  }

  if 'post_json' in $service_config['probes'][0] {
    $post_json = {
      'method'  => 'POST',
      'body'    => $service_config['probes'][0]['post_json'],
      'headers' => {
        'Content-Type' => 'application/json',
      },
    }
  } else {
    $post_json = {}
  }

  if 'host' in $service_config['probes'][0] {
    $host_header = {
      'headers' => {
        'Host' => $service_config['probes'][0]['host'],
      },
    }
  } else {
    $host_header = {}
  }

  return deep_merge($compat, $match, $post_json, $host_header)
}
