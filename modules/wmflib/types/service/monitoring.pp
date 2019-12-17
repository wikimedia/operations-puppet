# Describes the monitoring we want to apply to a service, at the load-balancer
# layer.
# @param [String] check_command
#     The check to perform on the LVS IP of the service
# @param [Hash] sites  List of sitename: {hostname: <host_to_check>} indicating the hostname to use for each site.
# @param [Boolean] critical  If the failure of the check should page or not.
# @param [Optional[String]] contact_group The contact group to notify of the failure. Defaults to 'admins'
type Wmflib::Service::Monitoring = Struct[{
    'check_command' => String,
    'sites'         => Hash[String, Struct[{'hostname' => Stdlib::Fqdn}]],
    'critical'      => Boolean,
    'contact_group' => Optional[String], # TODO: this should really be an array of strings.
}]
