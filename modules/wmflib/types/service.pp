# @type Wmflib::service
# Define all data pertaining to a service.
# Of specific interest might be the "state", which represent the status in a
# state machine of the specific service we're declaring.
# If modified, update also spicerack.service.Service.
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
# @param [Optional[Wmflib::Service::Probes]] probes
#     A list of network probes for the service.
# @param [Optional[Boolean] page
#     Whether the service should page (defaults to true)
# @param Enum state
#     State on the state machine of installation of the service.
#     Specifically:
#     - service_setup means we need the declaration to be present for setting up the
#     service on real servers
#     - lvs_setup means we need the declaration to be present for setting up lvs
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
# @param Optional[Array[String]] public_aliases
#     A list of aliases for public names of the service. See also 'public_domain'.
#
type Wmflib::Service = Struct[
    {
    'description'     => String[1],
    'sites'           => Array[String[1]],
    'ip'              => Hash[String[1], Wmflib::Service::Ipblock],
    'port'            => Stdlib::Port, # This used to be optional in lvs config
    'encryption'      => Boolean, # Whether we need TLS to connect
    'lvs'             => Optional[Wmflib::Service::Lvs],
    'monitoring'      => Optional[Wmflib::Service::Monitoring],
    'probes'          => Optional[Wmflib::Service::Probes],
    'page'            => Optional[Boolean],
    'state'           => Enum['service_setup', 'lvs_setup', 'production'],
    'discovery'       => Optional[Wmflib::Service::Discovery],
    'role'            => Optional[String[1]],
    'public_endpoint' => Optional[String[1]],
    'aliases'         => Optional[Array[String[1]]],
    'public_aliases'  => Optional[Array[String[1]]],
    }
]
