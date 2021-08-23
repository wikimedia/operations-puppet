# @type Wmflib::service
# Define all data pertaining to a service.
# Of specific interest might be the "state", which represent the status in a
# state machine of the specific service we're declaring.
# @param [String] description
#     The description of the service
# @param Array[String] sites
#     The list of the datacenters where the service is active
# @param [Hash[String, Wmflib::Service::Ipblock]] ip
#     Hash of site names and corresponding LVS IPs.
# @param [Stdlib::Port] port
#     The IP port on which the service is exposed
# @param [Boolean] encryption
#     Whether the service uses TLS or not.
# @param [Wmflib::Service::Lvs] lvs
#     A collection of information on the load-balancing of the service
# @param [Optional[Wmflib::Service::Monitoring]] monitoring
#     A collection of information on the monitoring of the service.
# @param Enum state
#     State on the state machine of installation of the service.
#     Specifically:
#     - service_setup means we need the declaration to be present for setting up the
#     service on real servers
#     - lvs_setup means we need the declaration to be present for setting up lvs
#     - monitoring_setup means we want to introduce monitoring, but we still don't
#     want to page.
#     - finally production means the setup is complete and live in production.
# @param Optional[Array] discovery
#     Array of discovery records related to the current service, if any
# @param Optional[String] role
#     The role used to run the service. The parameter is optional and used to
#     associate the service to a list of hosts expected to run the service on $port.
# @param Optional[String] public_endpoint
#     The service's public name available under $public_domain. For example
#     'public_endpoint: logstash' in production will be available at
#     logstash.wikimedia.org. The parameter is optional for services not
#     publicly available (e.g. internal only or fronted by restbase)
# @param Optional[Array[String]] aliases
#     A list of alias names for the service. Useful for example to provide
#     legacy names still referenced by configurations.
#
type Wmflib::Service = Struct[
    {
    'description'     => String,
    'sites'           => Array[String],
    'ip'              => Hash[String, Wmflib::Service::Ipblock],
    'port'            => Stdlib::Port, # This used to be optional in lvs config
    'encryption'      => Boolean, # Wether we need TLS to connect
    'lvs'             => Optional[Wmflib::Service::Lvs],
    'monitoring'      => Optional[Wmflib::Service::Monitoring],
    'state'           => Enum['service_setup', 'lvs_setup', 'monitoring_setup', 'production'],
    'discovery'       => Optional[Wmflib::Service::Discovery],
    'role'            => Optional[String],
    'public_endpoint' => Optional[String],
    'aliases'         => Optional[Array[String]],
    }
]
