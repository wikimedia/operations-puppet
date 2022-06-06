# Select services that are active for this specific request.
# Allowed arguments are:
# - discovery, will return all services that have a discovery stanza and are in the right status.
function wmflib::service::get_services_for(Enum['discovery'] $what) >> Hash[String, Wmflib::Service] {
  if $what == 'discovery' {
      $needed_properties = ['discovery']
      $needed_statuses = ['production']
  }
  wmflib::service::fetch().filter |$name, $srv| {
      $present = $srv.keys.filter |$k| {$k in $needed_properties}
      ($srv['state'] in $needed_statuses and $present != [])
  }
}
