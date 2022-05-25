# Return the generic Blackbox module options

# TODO support options for more than one probe if/when needed
function wmflib::service::probe::module_options(
  String $service_name,
  Wmflib::Service $service_config,
) >> Hash {

  if 'probes' in $service_config {
    $probe = $service_config['probes'][0]
  } else {
    $probe = {}
  }

  $timeout = {
    timeout => pick($probe['timeout'], '3s')
  }

  # Use 'return deep_merge(...)' with more than one hash
  return $timeout
}
