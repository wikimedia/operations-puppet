# Select services that belong to this LVS server.
# We're selecting services that are:
# - in the lvs class of this server (or this server is secondary)
# - in a state different from 'service_setup'
# - configured in the datacenter we're in.
#
function wmflib::service::get_services_for_lvs(String $class, String $site) >> Hash[String, Wmflib::Service] {
  include profile::lvs::configuration
  wmflib::service::fetch(true).filter |$name, $srv| {
        $srv['state'] != 'service_setup' and $profile::lvs::configuration::lvs_class in [$srv['lvs']['class'], 'secondary'] and $site in $srv['sites']
  }
}
