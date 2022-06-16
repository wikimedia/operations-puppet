# @type Wmflib::Service::Lvs
# Define all the variables related to configuring LVS.
# If modified, update also spicerack.service.ServiceLVS
# @param [Boolean] enabled Is the service enabled or not on the load balancers
# @param [Enum] class lvs class of the service
# @param [Optional[Enum]] scheduler the IPVS scheduler to use when load-balancing the service. Defaults to 'wrr'.
# @param [Struct] conftool  the conftool metadata for the service.
# @param [String] depool_threshold  the percentage of the cluster that will be kept pooled by Pybal even if checks fail
# @param [Hash] monitors
#    Which Pybal monitors to configure. For details, see the Pybal documentation. Configuration options are written as key: value
# @param [Optional[Boolean]] bgp  Whether to advertise the service via bgp, or not. Defaults to true
# @param [Optional[Enum]] protocol  Whether the service uses tcp or udp. Defaults to 'tcp'.
type Wmflib::Service::Lvs = Struct[{
    'enabled'           => Boolean,
    'class'             => Enum['low-traffic', 'high-traffic1', 'high-traffic2'],
    'scheduler'         => Optional[Enum['rr', 'wrr', 'lc', 'wlc', 'lblc', 'lblcr', 'dh', 'sh', 'sed', 'nq']],
    'conftool'          => Struct[{'cluster' => String[1], 'service' => String[1]}],
    'depool_threshold'  => String[1],
    'monitors'          => Hash[Enum['ProxyFetch', 'IdleConnection', 'UDP'], Hash],
    'bgp'               => Optional[Boolean],
    'protocol'          => Optional[Enum['tcp', 'udp']],
}]
