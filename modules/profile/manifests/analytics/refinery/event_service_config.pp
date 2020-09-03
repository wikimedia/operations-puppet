# Class: profile::analytics::refinery::event_service_config
#
# Looks up service URLs for event_service_names in each of the datacenters,
# and renders a yaml mapping of event_service_name-dc: url.
#
# Parameters:
#
# [*event_service_names*]
#   List of service names to lookup in service::catalog.
#
# [*sites*]
#   List of sites (datacenters) for which we want URLs.
#   'discovery', means the non DC specific discovery URL,
#   any other value means a datacenter specific LVS svc URL.
#   Datacenter specific event service names will be suffixed with -$datacenter
#   in the resulting map.  E.g.
#       eventgate-main: https://eventgate-main.discovery.wmnet:4492/v1/events
#       eventgate-main-eqiad: https://eventgate-main.svc.eqiad.wmnet:4492/v1/events
#
class profile::analytics::refinery::event_service_config(
    Array[String] $event_service_names = lookup(
        'profile::analytics::refinery::event_service_config::event_service_names',
        {'default_value' => [
            'eventgate-main',
            'eventgate-analytics',
            'eventgate-analytics-external',
            'eventgate-logging-external',
        ]}
    ),
    Array[String] $sites = lookup(
        'profile::analytics::refinery::event_service_config::datacenters',
        {'default_value' => [
            'discovery', 'eqiad', 'codfw'
        ]},
    )
) {

    $uri_path = '/v1/events'

    # Map $event_service_names to a List of List of Tuples[event_service_name-site, url],
    # then flatten the list and create a Hash out of that.
    $event_service_name_to_uri = Hash($event_service_names.map |$event_service_name| {
        $sites.map |$site| {
            $url = wmflib::service::get_url($event_service_name, $uri_path, undef, $site)
            $event_service_key = $site ? {
                'discovery' => $event_service_name,
                default => "${event_service_name}-${site}"
            }
            Tuple([$event_service_key, $url])
        }
    }.flatten())

    $event_intake_service_url_config_file = "${::profile::analytics::refinery::config_dir}/event_intake_service_urls.yaml"
    file { $event_intake_service_url_config_file:
        # $event_service_name_to_uri should be a key val Hash, so we can just
        # render our config file the Hash converted to Yaml.
        content => ordered_yaml($event_service_name_to_uri),
    }

}
