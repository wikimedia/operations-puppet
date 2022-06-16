# Describes the monitoring we want to apply to a service, at the load-balancer
# If modified, update also spicerack.service.Monitoring.
# layer.
# @param [String] check_command
#     The check to perform on the LVS IP of the service
# @param [Hash] sites  List of sitename: {hostname: <host_to_check>} indicating the hostname to use for each site.
# @param [Optional[String]] contact_group The contact group to notify of the failure. Defaults to 'admins'
type Wmflib::Service::Monitoring = Struct[{
    'check_command' => String[1],
    'sites'         => Hash[String[1], Struct[{'hostname' => Stdlib::Fqdn}]],
    'contact_group' => Optional[String[1]], # TODO: this should really be an array of strings.
    'notes_url'     => Optional[String[1]],
}]
