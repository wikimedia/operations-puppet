# Select services that are active for this specific request.
# Allowed arguments are:
# - monitoring, will return all lvs services that have a monitoring stanza and are in the right status.
# - discovery, will return all services that have a discovery stanza and are in the right status.
function wmflib::service::get_services_for(Enum['monitoring', 'discovery'] $what) >> Hash[String, Wmflib::Service] {
  if $what == 'monitoring' {
      # List of properties you need one of to be included
      $needed_properties = ['monitoring', 'probes']
      $needed_statuses = ['monitoring_setup', 'production']
  } elsif $what == 'discovery' {
      $needed_properties = ['discovery']
      $needed_statuses = ['monitoring_setup', 'production']
  }
  wmflib::service::fetch().filter |$name, $srv| {
      $present = $srv.keys.filter |$k| {$k in $needed_properties}
      $srv['state'] in $needed_statuses and $present
  }
}
